# frozen_string_literal: true

module Folio
  class GenerateThumbnailJob < ApplicationJob
    queue_as :default

    def perform(image, size, quality)
      return if image.thumbnail_sizes[size]

      image.thumbnail_sizes[size] = compute_sizes(image, size)
      image.update!(thumbnail_sizes: image.thumbnail_sizes)

      ActionCable.server.broadcast(::FolioThumbnailsChannel::STREAM,
        temporary_url: URI.encode(image.temporary_url(size)),
        temporary_s3_url: URI.encode(image.temporary_s3_url(size)),
        url: URI.encode(image.thumbnail_sizes[size][:url])
      )
    end

    private

      def compute_sizes(image, size)
        return if image.thumbnail_sizes[size]

        thumbnail = image.file
                         .thumb(size, 'format' => :jpg, 'frame' => 0)
                         .encode('jpg', "-quality #{quality}")
        {
          uid: thumbnail.store,
          signature: thumbnail.signature,
          url: thumbnail.url,
          width: thumbnail.width,
          height: thumbnail.height,
          quality: quality
        }
      end
  end
end
