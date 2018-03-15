# frozen_string_literal: true

class FolioThumbnailsChannel < ApplicationCable::Channel
  STREAM = 'folio_thumbnails'

  def subscribed
    stream_from STREAM
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
