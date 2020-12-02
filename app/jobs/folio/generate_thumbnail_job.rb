# frozen_string_literal: true

class Folio::GenerateThumbnailJob < Folio::ApplicationJob
  queue_as :default

  def perform(image, size, quality, x: nil, y: nil, force: false)
    return if /svg/.match?(image.mime_type)

    # need to reload here because of parallel jobs
    image.reload

    thumbnail_sizes = image.thumbnail_sizes || {}
    present_uid = thumbnail_sizes[size] && thumbnail_sizes[size][:uid]
    return if !force && present_uid

    Dragonfly.app.datastore.destroy(present_uid) if present_uid

    new_thumb = make_thumb(image, size, quality, x: x, y: y)

    # need to reload here because of parallel jobs
    image.with_lock do
      image.reload
      thumbnail_sizes = image.thumbnail_sizes || {}
      image.update!(thumbnail_sizes: thumbnail_sizes.merge(size => new_thumb))
    end

    ActionCable.server.broadcast(FolioThumbnailsChannel::STREAM,
      temporary_url: image.temporary_url(size),
      temporary_s3_url: image.temporary_s3_url(size),
      url: new_thumb[:url],
      webp_url: new_thumb[:webp_url],
      width: new_thumb[:width],
      height: new_thumb[:height],
    )

    image
  end

  private
    def make_thumb(image, size, quality, x: nil, y: nil)
      if /png/.match?(image.try(:mime_type))
        if Rails.application.config.folio_dragonfly_keep_png
          thumbnail = image.file
                           .thumb(size, format: :png,
                                        x: x,
                                        y: y)
        else
          thumbnail = image.file
                           .add_white_background
                           .thumb(size, format: :jpg,
                                        x: x,
                                        y: y)
                           .encode("jpg", "-quality #{quality}")
                           .jpegoptim
        end
      elsif image.animated_gif?
        thumbnail = image.file
                         .animated_gif_resize(size)
      elsif /pdf/.match?(image.try(:mime_type))
        # "frame" option has to be set as string key
        # https://github.com/markevans/dragonfly/issues/483
        thumbnail = image.file
                         .add_white_background
                         .thumb(size, format: :jpg,
                                      "frame" => 0,
                                      x: x,
                                      y: y)
                         .encode("jpg", "-quality #{quality}")
                         .jpegoptim
      else
        thumbnail = image.file
                         .thumb(size, format: :jpg,
                                      x: x,
                                      y: y)
                         .auto_orient
                         .encode("jpg", "-quality #{quality}")
                         .cmyk_to_srgb
                         .jpegoptim
      end

      uid = thumbnail.store

      {
        uid: uid,
        signature: thumbnail.signature,
        url: Dragonfly.app.datastore.url_for(uid),
        width: thumbnail.width,
        height: thumbnail.height,
        quality: quality,
        x: x,
        y: y,
      }
    end
end
