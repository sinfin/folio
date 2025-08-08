# frozen_string_literal: true

class Folio::Files::RestartProcessingMediaJob < Folio::ApplicationJob
  queue_as :slow

  def perform
    Folio::File.processing.find_each do |file|
      if file.remote_services_data.blank?
        file.process_attached_file

      else
        started_at = file.remote_services_data["processing_step_started_at"]
        next if started_at && started_at < 1.hour.ago

        case file.processing_state
        when "enqueued"
          file.create_full_media
        when "full_media_processing"
          file.check_media_processing(preview: false)
        when "full_media_processed"
          file.create_preview_media
        when "preview_media_processing"
          file.check_media_processing(preview: true)
        when "preview_media_processed"
          file.processing_done!
        end
      end
    end
  end
end
