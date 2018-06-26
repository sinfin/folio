# frozen_string_literal: true

module Folio
  class GenerateThumbnailJob < ApplicationJob
    queue_as :default

    def perform(image, size, quality)
      return if image.thumbnail_sizes[size]
      return if image.mime_type =~ /svg/

      image.thumbnail_sizes[size] = compute_sizes(image, size, quality)
      image.update!(thumbnail_sizes: image.thumbnail_sizes)

      ActionCable.server.broadcast(::FolioThumbnailsChannel::STREAM,
        temporary_url: URI.encode(image.temporary_url(size)),
        temporary_s3_url: URI.encode(image.temporary_s3_url(size)),
        url: URI.encode(image.thumbnail_sizes[size][:url])
      )

      image
    end

    private

      def compute_sizes(image, size, quality)
        return if image.thumbnail_sizes[size]

        if Rails.application.config.folio_dragonfly_keep_png &&
           image.try(:mime_type) =~ /png/
          thumbnail = image.file
                           .thumb(size)
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

      def shell(*command)
        cmd = command.join(' ')

        _stdout, _stderr, status = Open3.capture3(*command)

        unless status == 0
          fail "Failed: '#{cmd}' failed with '#{stderr.chomp}'. Stdout: '#{stdout.chomp}'."
        end
      end
  end
end
