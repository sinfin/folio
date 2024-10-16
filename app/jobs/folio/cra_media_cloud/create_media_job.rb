# frozen_string_literal: true

class Folio::CraMediaCloud::CreateMediaJob < Folio::ApplicationJob
  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(media_file)
    fail "only video files are supported" unless media_file.is_a?(Folio::File::Video)

    original_remote_id = media_file.remote_id

    response = Folio::CraMediaCloud::Encoder.new.upload_file(media_file)

    media_file.remote_services_data = {
      "service" => "cro_media_cloud",
      "reference_id" => response[:ref_id],
      "processing_state" => "full_media_processing"
    }
    media_file.save!

    Folio::CraMediaCloud::CheckProgressJob.set(wait: 1.minute).perform_later(media_file)
    Folio::CraMediaCloud::DeleteMediaJob.perform_later(original_remote_id) if original_remote_id.present?

    broadcast_file_update(media_file)
  end
end
