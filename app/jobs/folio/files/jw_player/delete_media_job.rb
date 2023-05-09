# frozen_string_literal: true

class Folio::Files::JwPlayer::DeleteMediaJob < ApplicationJob
  queue_as :default

  def perform(media_file)
    if media_file.remote_key.present?
      Folio::JwPlayer::Api.new(media_file).delete_media(preview: false)
    end

    if media_file.remote_preview_key.present?
      Folio::JwPlayer::Api.new(media_file).delete_media(preview: true)
    end
  end
end
