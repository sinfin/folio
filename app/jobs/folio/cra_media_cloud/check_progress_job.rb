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
    else
      media_file.save! if media_file.changed?
      check_again_later
    end
  end

  private
    def fetch_job_response
      if media_file.remote_id.present?
        api.get_job(media_file.remote_id)
      elsif media_file.remote_reference_id.present?
        api.get_jobs(ref_id: media_file.remote_reference_id).first
      else
        raise "Missing remote_key and remote_reference_id"
      end
    end

    def update_remote_service_data(response)
      media_file.remote_services_data["remote_id"] ||= response["id"]

      if response["status"] == "DONE"
        process_output_hash(response["output"])

        media_file.remote_services_data.merge!(
          "output" => response["output"],
          "processing_state" => "full_media_processed"
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
      Folio::CraMediaCloud::CheckProgressJob.set(wait: 30.seconds).perform_later(media_file)
    end

    def api
      Folio::CraMediaCloud::Api.new
    end
end
