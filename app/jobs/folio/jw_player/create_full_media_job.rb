# frozen_string_literal: true

class Folio::JwPlayer::CreateFullMediaJob < Folio::ApplicationJob
  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(media_file)
    response = Folio::JwPlayer::Api.new(media_file).create_media

    if response["status"] == "processing"
      rs_data = media_file.remote_services_data.presence || {}
      original_remote_key = rs_data["remote_key"]

      media_file.remote_services_data = rs_data.merge({
        "service" => "jw_player",
        "remote_key" => response["id"],
        "processing_state" => "full_media_processing"
      })
      media_file.save!

      Folio::JwPlayer::CheckProgressJob.set(wait: 10.seconds).perform_later(media_file, preview: false)
      Folio::JwPlayer::DeleteMediaJob.perform_later(original_remote_key) if original_remote_key.present?

      broadcast_file_update(media_file)
    else
      fail response.to_s
    end
  end
end
