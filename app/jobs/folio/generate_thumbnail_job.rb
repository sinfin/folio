# frozen_string_literal: true

module Folio
  class GenerateThumbnailJob < ApplicationJob
    queue_as :default

    def perform(image, size, quality)
      return if image.thumbnail_sizes[size] && image.thumbnail_sizes[size][:uid]
      return if image.mime_type =~ /svg/

      image.thumbnail_sizes[size] = compute_sizes(image, size, quality)
      image.update!(thumbnail_sizes: image.thumbnail_sizes)

      ActionCable.server.broadcast(::FolioThumbnailsChannel::STREAM,
        temporary_url: image.temporary_url(size),
        temporary_s3_url: image.temporary_s3_url(size),
        url: image.thumbnail_sizes[size][:url],
        width: image.thumbnail_sizes[size][:width],
        height: image.thumbnail_sizes[size][:height]
      )

      image
    end

    private

      def compute_sizes(image, size, quality)
        return if image.thumbnail_sizes[size] && image.thumbnail_sizes[size][:uid]

        if /png/.match?(image.try(:mime_type))
          if Rails.application.config.folio_dragonfly_keep_png
            thumbnail = image.file
                             .thumb(size, 'format' => :png, 'frame' => 0)
          else
            thumbnail = image.file
                             .add_white_background
                             .thumb(size, 'format' => :jpg, 'frame' => 0)
                             .encode('jpg', "-quality #{quality}")
                             .jpegoptim
          end
        elsif image.animated_gif?
          thumbnail = image.file
                           .animated_gif_resize(size)
        elsif /pdf/.match?(image.try(:mime_type))
          thumbnail = image.file
                           .add_white_background
                           .thumb(size, 'format' => :jpg, 'frame' => 0)
                           .encode('jpg', "-quality #{quality}")
                           .jpegoptim
        else
          thumbnail = image.file
                           .thumb(size, 'format' => :jpg, 'frame' => 0)
                           .cmyk_to_srgb
                           .encode('jpg', "-quality #{quality}")
                           .jpegoptim
        end

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
