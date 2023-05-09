# frozen_string_literal: true

class Folio::Files::JwPlayer::CheckProgressJob < ApplicationJob
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
      response = Folio::JwPlayer::Api.new(media_file).check_media
      return nil if response.has_key?("message")

      if response["status"] == "ready"
        media_file.remote_services_data["metadata"] = response
        if @preview
          media_file.preview_media_processed!
        else
          media_file.full_media_processed!
        end
      else
        nil
      end
    end
end
