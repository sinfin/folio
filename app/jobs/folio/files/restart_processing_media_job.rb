# frozen_string_literal: true

class Folio::Files::RestartProcessingMediaJob < Folio::ApplicationJob
  queue_as :slow

  def perform
    restart_stuck_media_processing
    restart_stuck_subtitle_processing
  end

  private
    def restart_stuck_media_processing
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

    def restart_stuck_subtitle_processing
      return unless defined?(Folio::File::Video)

      Folio::File::Video.where(aasm_state: :ready).find_each do |video_file|
        next unless video_file.class.subtitles_enabled?

        video_file.class.enabled_subtitle_languages.each do |lang|
          state = video_file.get_subtitles_state_for(lang)
          next unless state == "processing"

          # Check if subtitle has been processing for more than 1 hour
          if video_file.updated_at < 1.hour.ago
            Rails.logger.info "[RestartProcessingMediaJob] Resetting stuck subtitle processing for video #{video_file.id}, language: #{lang}"
            video_file.set_subtitles_state_for(lang, "failed")
            video_file.update_columns(additional_data: video_file.additional_data, updated_at: Time.current)
          end
        end
      end
    end
end
