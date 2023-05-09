# frozen_string_literal: true

class Folio::Files::JwPlayer::CreatePreviewMediaJob < Folio::ApplicationJob
  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(media_file)
    return if media_file.remote_preview_key.present?

    response = Folio::JwPlayer::Api.new(media_file).create_media(preview: true)

    if response["status"] == "processing"
      rs_data = media_file.remote_services_data.presence || {}
      original_remote_key = rs_data["remote_preview_key"]

      media_file.remote_services_data = rs_data.merge({
        "service" => "jw_player",
        "remote_preview_key" => response["id"],
        "processing_state" => "preview_media_processing",
        "preview_inteval" => media_file.preview_inteval
      })
      media_file.save!

      Folio::Files::JwPlayer::CheckProgressJob.set(wait: 10.seconds).perform_later(media_file, preview: true)
      Folio::Files::JwPlayer::DeleteMediaJob.perform_later(original_remote_key) if original_remote_key.present?
    else
      fail response.to_s
    end
  end
end
