# frozen_string_literal: true

class Folio::Mux::CreateFullMediaJob < Folio::ApplicationJob
  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(media_file)
    response = Folio::Mux::Api.new(media_file).create_media

    if response.data.status == "preparing"
      rs_data = media_file.remote_services_data.presence || {}
      original_remote_key = rs_data["remote_key"]

      media_file.remote_services_data = rs_data.merge({
        "service" => "mux",
        "remote_key" => response.data.id,
        "processing_state" => "full_media_processing"
      })
      media_file.save!

      Folio::Mux::CheckProgressJob.set(wait: 10.seconds).perform_later(media_file, preview: false)
      Folio::Mux::DeleteMediaJob.perform_later(original_remote_key) if original_remote_key.present?
    else
      fail response.to_s
    end
  end
end
