# frozen_string_literal: true

class Folio::CraMediaCloud::CheckProgressJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  attr_reader :media_file

  def perform(media_file)
    @media_file = media_file

    response = fetch_job_response

    return check_again_later if response.nil?

    update_remote_service_data(response)

    if media_file.full_media_processed?
      media_file.processing_done!
      broadcast_file_update(media_file)
    elsif media_file.changed?
      media_file.save!
      broadcast_file_update(media_file)
      check_again_later
    else
      check_again_later
    end
  end

  private
    def fetch_job_response
      if media_file.remote_id.present?
        api.get_job(media_file.remote_id)
      elsif media_file.remote_reference_id.present?
        api.get_jobs(ref_id: media_file.remote_reference_id).last
      else
        # No remote references exist, create a new upload job (with deduplication)
        if should_create_media_job?
          Rails.logger.info "[CraMediaCloud::CheckProgressJob] No remote_id or remote_reference_id found for #{media_file.class.name} ID #{media_file.id}. Creating new CreateMediaJob."
          
          # Mark that we're creating a job to prevent duplicates
          media_file.with_lock do
            media_file.remote_services_data = (media_file.remote_services_data || {}).merge({
              "service" => "cra_media_cloud",
              "processing_state" => "creating_media_job",
              "processing_step_started_at" => Time.current.iso8601
            })
            media_file.save!
          end
          
          Folio::CraMediaCloud::CreateMediaJob.perform_later(media_file)
        else
          Rails.logger.info "[CraMediaCloud::CheckProgressJob] CreateMediaJob already scheduled or in progress for #{media_file.class.name} ID #{media_file.id}. Skipping."
        end
        return nil  # Return nil to stop processing this check job
      end
    end

    def update_remote_service_data(response)
      media_file.remote_services_data["remote_id"] ||= response["id"]
      
      case response["status"]
      when "DONE"
        process_output_hash(response["output"])

        media_file.remote_services_data.merge!(
          "output" => response["output"],
          "processing_state" => "full_media_processed",
        )
      when "PROCESSING"
        media_file.remote_services_data.merge!(
          "processing_state" => "full_media_processing",
          "progress_percentage" => (response["progress"] ? response["progress"] * 100.0 : 0).round(1),
        )
      end
    end

    def process_output_hash(process_output_hash)
      content_mp4_paths = {}
      manifest_hls, manifest_dash = nil, nil

      process_output_hash.each do |output_file|
        case output_file["type"]
        when "MP4"
          content_mp4_paths[output_file["profiles"].first] = output_file["path"]
        when "HLS"
          manifest_hls = select_output_file(manifest_hls, output_file)
        when "DASH"
          manifest_dash = select_output_file(manifest_dash, output_file)
        when "THUMBNAILS"
          update_thumbnail_path(output_file)
        end
      end

      media_file.remote_services_data.merge!(
        "content_mp4_paths" => content_mp4_paths,
        "manifest_hls_path" => manifest_hls["path"],
        "manifest_dash_path" => manifest_dash["path"],
      )
    end

    def select_output_file(current, incoming)
      current.present? && current["profiles"].count > incoming["profiles"].count ? current : incoming
    end

    def update_thumbnail_path(output_file)
      case output_file["profiles"]
      when ["cover"]
        media_file.remote_services_data["cover_path"] = output_file["path"]
      when ["thumb"]
        media_file.remote_services_data["thumbnails_path"] = output_file["path"]
      end
    end

    def check_again_later
      Folio::CraMediaCloud::CheckProgressJob.set(wait: 15.seconds).perform_later(media_file)
    end

    def should_create_media_job?
      # Check if we already have a CreateMediaJob scheduled for this video
      return false if create_media_job_scheduled?
      
      # Check if the video is already in a state where CreateMediaJob has been triggered
      processing_state = media_file.remote_services_data&.dig("processing_state")
      started_at = media_file.remote_services_data&.dig("processing_step_started_at")
      
      if processing_state == "creating_media_job"
        # If it's been more than 5 minutes since we started creating the job, allow retry
        if started_at && Time.parse(started_at) < 10.minutes.ago
          Rails.logger.warn "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} has been in creating_media_job state for >5 minutes, allowing retry"
          return true
        else
          return false
        end
      end
      
      # Check if the video is already in processing state
      return false if processing_state == "full_media_processing"
      
      # Allow retry for failed uploads after some time
      if processing_state == "upload_failed"
        if started_at && Time.parse(started_at) < 15.minutes.ago
          Rails.logger.info "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} upload failed >10 minutes ago, allowing retry"
          return true
        else
          return false
        end
      end
      
      true
    rescue => e
      Rails.logger.error "[CraMediaCloud::CheckProgressJob] Error checking if CreateMediaJob should be created: #{e.message}"
      false
    end
    
    def create_media_job_scheduled?
      # Check Sidekiq scheduled jobs
      Sidekiq::ScheduledSet.new.any? do |job|
        args = job.args.first
        if args.is_a?(Hash) && args["job_class"] == "Folio::CraMediaCloud::CreateMediaJob"
          global_id = args["arguments"].first["_aj_globalid"]
          global_id.include?("Folio::File::Video") && global_id.split("/").last.to_i == media_file.id
        end
      end
    rescue => e
      Rails.logger.error "[CraMediaCloud::CheckProgressJob] Error checking scheduled CreateMediaJob: #{e.message}"
      false
    end

    def api
      @api ||= Folio::CraMediaCloud::Api.new
    end
end
