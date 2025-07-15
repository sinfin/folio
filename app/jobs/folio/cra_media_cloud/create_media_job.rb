# frozen_string_literal: true

class Folio::CraMediaCloud::CreateMediaJob < Folio::ApplicationJob
  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(media_file)
    fail "only video files are supported" unless media_file.is_a?(Folio::File::Video)

    # Use database locking to prevent race conditions
    media_file.with_lock do
      # Double-check that we should still create this job
      if media_file.remote_id.present? || media_file.remote_reference_id.present?
        Rails.logger.info "[CraMediaCloud::CreateMediaJob] Video #{media_file.id} already has remote references, skipping upload"
        return
      end

      original_remote_id = media_file.remote_id
      original_remote_reference_id = media_file.remote_reference_id

      Rails.logger.info "[CraMediaCloud::CreateMediaJob] Starting upload for video #{media_file.id}"

      begin
        response = Folio::CraMediaCloud::Encoder.new.upload_file(media_file, profile_group: media_file.try(:encoder_profile_group))

        media_file.remote_services_data = {
          "service" => "cra_media_cloud",
          "reference_id" => response[:ref_id],
          "processing_state" => "full_media_processing",
          "processing_step_started_at" => Time.current.iso8601
        }
        media_file.save!

        Rails.logger.info "[CraMediaCloud::CreateMediaJob] Upload completed for video #{media_file.id}, reference_id: #{response[:ref_id]}"

        # Schedule progress check
        Folio::CraMediaCloud::CheckProgressJob.set(wait: 1.minute).perform_later(media_file)

        # Clean up old media if it exists
        if original_remote_id || original_remote_reference_id
          Folio::CraMediaCloud::DeleteMediaJob.perform_later(original_remote_id, reference_id: original_remote_reference_id)
        end

        broadcast_file_update(media_file)
      rescue => e
        # Reset state on error to allow future retries
        Rails.logger.error "[CraMediaCloud::CreateMediaJob] Upload failed for video #{media_file.id}: #{e.message}"
        
        media_file.remote_services_data = (media_file.remote_services_data || {}).merge({
          "processing_state" => "upload_failed",
          "error_message" => e.message,
          "processing_step_started_at" => Time.current.iso8601
        })
        media_file.save!
        
        broadcast_file_update(media_file)
        raise e
      end
    end
  end
end
