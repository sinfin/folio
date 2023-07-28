# frozen_string_literal: true

class Folio::JwPlayer::CheckProgressJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError
  retry_on Folio::JwPlayer::MetadataNotAvailable, wait: 30.seconds, attempts: 25

  queue_as :default

  attr_reader :media_file, :preview

  def perform(media_file, preview: false)
    @media_file = media_file
    @preview = preview
    key = preview ? media_file.remote_preview_key : media_file.remote_key

    raise "Missing remote_#{preview ? "preview" : ""}_key" if key.nil?

    update_jw_metadata! || raise(Folio::JwPlayer::MetadataNotAvailable)
  end

  private
    def update_jw_metadata!
      response = Folio::JwPlayer::Api.new(media_file).check_media(preview: @preview)
      return nil if response.has_key?("message")

      if response["status"] == "ready"
        if @preview
          media_file.remote_services_data["preview"] = response
          media_file.preview_media_processed!
        else
          media_file.remote_services_data["full"] = response
          media_file.full_media_processed!
        end

        broadcast_file_update(media_file)
      elsif response["status"] == "failed"
        media_file.remote_services_data["error"] = response["error_message"]
        media_file.processing_failed!

        broadcast_file_update(media_file)

        raise "JwPlayer error: #{response["error_message"]}"
      end
    end
end
