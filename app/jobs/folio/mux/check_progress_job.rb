# frozen_string_literal: true

class Folio::Mux::CheckProgressJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError
  retry_on Folio::Mux::MetadataNotAvailable, wait: 30.seconds, attempts: 25

  queue_as :default

  attr_reader :media_file, :preview

  def perform(media_file, preview: false)
    @media_file = media_file
    @preview = preview
    key = preview ? media_file.remote_preview_key : media_file.remote_key

    raise "Missing remote_#{preview ? "preview" : ""}_key" if key.nil?

    update_mux_metadata! || raise(Folio::Mux::MetadataNotAvailable)
  end

  private
    def update_mux_metadata!
      response = Folio::Mux::Api.new(media_file).check_media(preview: @preview)

      if response.data.status == "ready" && response.data.static_renditions.status == "ready"
        if @preview
          media_file.remote_services_data["preview"] = response.data
          media_file.preview_media_processed!
        else
          media_file.remote_services_data["full"] = response.data
          media_file.full_media_processed!
        end

        broadcast_file_update(media_file)
      elsif response.data.status == "errored"
        media_file.remote_services_data["error"] = response.data.errors
        media_file.processing_failed!

        broadcast_file_update(media_file)

        raise "Mux error: #{response.data.errors}"
      end
    end
end
