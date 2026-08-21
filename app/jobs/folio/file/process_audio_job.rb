# frozen_string_literal: true

class Folio::File::ProcessAudioJob < Folio::ApplicationJob
  queue_as :default

  def perform(audio_file)
    return unless audio_file.is_a?(Folio::File::Audio)

    audio_file.retry_processing! if audio_file.processing_failed?

    begin
      Folio::File::AudioProcessingService.new(audio_file).call
    rescue StandardError => error
      handle_failure(audio_file, error)
      raise
    end

    safe_broadcast_file_update(audio_file)
  end

  private
    def safe_broadcast_file_update(audio_file)
      broadcast_file_update(audio_file)
    rescue StandardError => error
      Rails.logger.warn("[ProcessAudioJob] broadcast failed for audio file ##{audio_file.id}: #{error.message}")
    end

    def handle_failure(audio_file, error)
      return unless audio_file&.persisted?

      remote_services_data = audio_file.remote_services_data.to_h.merge(
        "error" => error.message,
        "processed_at" => Time.current.iso8601,
      )

      audio_file.update_columns(
        aasm_state: "processing_failed",
        remote_services_data: remote_services_data,
        updated_at: Time.current
      )

      safe_broadcast_file_update(audio_file)
    end
end
