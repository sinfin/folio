# frozen_string_literal: true

class Folio::CraMediaCloud::CheckProgressJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  attr_reader :media_file

  def perform(media_file, preview: false, encoding_generation: nil)
    @media_file = media_file
    @encoding_generation = encoding_generation
    # CraMediaCloud doesn't use preview parameter, but we accept it for consistency

    # If encoding_generation is provided, check if it matches current generation
    # This prevents stale jobs from interfering with newer encodings
    if @encoding_generation.present? && media_file.encoding_generation != @encoding_generation
      Rails.logger.info "[CraMediaCloud::CheckProgressJob] Skipping stale job for #{media_file.class.name}##{media_file.id} " \
                        "(job generation: #{@encoding_generation}, current: #{media_file.encoding_generation})"
      return
    end

    # Early return if video doesn't need progress checking
    if media_file.ready?
      Rails.logger.info "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} is already in ready state, skipping progress check"
      return
    end

    response = fetch_job_response

    return check_again_later if response.nil?

    update_remote_service_data(response)

    if media_file.full_media_processed?
      media_file.processing_done!
      broadcast_file_update(media_file)
    elsif media_file.upload_failed?
      # Don't reschedule for failed uploads - MonitorProcessingJob will handle retries
      media_file.save!
      broadcast_file_update(media_file)
      Rails.logger.info "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} upload failed, not rescheduling"
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
        jobs = api.get_jobs(ref_id: media_file.remote_reference_id)
        if jobs.empty?
          Rails.logger.warn "[CraMediaCloud::CheckProgressJob] No jobs found for reference_id #{media_file.remote_reference_id}"
          return nil
        end
        # Get the most recent job by lastModified
        job = jobs.max_by { |j| Time.parse(j["lastModified"]) }
        Rails.logger.debug "[CraMediaCloud::CheckProgressJob] Found #{jobs.size} job(s) for #{media_file.remote_reference_id}, using most recent from #{job['lastModified']}"
        job
      else
        # No remote references exist - this should be handled by MonitorProcessingJob
        Rails.logger.info "[CraMediaCloud::CheckProgressJob] No remote_id or remote_reference_id found for #{media_file.class.name} ID #{media_file.id}. MonitorProcessingJob should handle this."
        nil  # Return nil to stop processing this check job
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
      when "PROCESSING", "CREATED"
        media_file.remote_services_data.merge!(
          "processing_state" => "full_media_processing",
          "progress_percentage" => (response["progress"] ? response["progress"] * 100.0 : 0).round(1),
        )
      when "FAILED", "ERROR"
        error_messages = response["messages"]&.filter_map { |msg| msg["message"] if msg["type"] == "ERROR" }&.join("; ")

        media_file.remote_services_data.merge!(
          "processing_state" => "upload_failed",
          "error_message" => error_messages || "Upload failed",
          "failed_at" => Time.current.iso8601,
          "progress_percentage" => nil
        )

        Rails.logger.error "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} failed: #{error_messages}"
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
      # Pass encoding_generation to ensure stale jobs don't interfere
      Folio::CraMediaCloud::CheckProgressJob.set(wait: 15.seconds).perform_later(
        media_file,
        encoding_generation: @encoding_generation || media_file.encoding_generation
      )
    end

    def api
      @api ||= Folio::CraMediaCloud::Api.new
    end
end
