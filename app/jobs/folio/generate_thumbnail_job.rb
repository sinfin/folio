# frozen_string_literal: true

module Folio
  class GenerateThumbnailJob < ApplicationJob
    queue_as :default

    def perform(image, size)
      return if image.thumbnail_sizes[size]

      image.thumbnail_sizes[size] = compute_sizes(image, size)
      image.update_attributes(thumbnail_sizes: image.thumbnail_sizes)
    end

    private

      def compute_sizes(image, size)
        return if image.thumbnail_sizes[size]

        thumbnail = image.file
                         .thumb(size, 'format' => :jpg, 'frame' => 0)
                         .encode('jpg', '-quality 90')
        {
          uid: thumbnail.store,
          signature: thumbnail.signature,
          url: thumbnail.url,
          width: thumbnail.width,
          height: thumbnail.height
        }
      end
  end
end
