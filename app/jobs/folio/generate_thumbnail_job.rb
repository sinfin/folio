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

    cable_urls = {}

    if new_thumb[:private]
      cable_urls[:url] = Dragonfly.app.datastore.url_for(new_thumb[:uid], expires: 1.hour.from_now)

      if new_thumb[:webp_url]
        cable_urls[:webp_url] = Dragonfly.app.datastore.url_for(new_thumb[:webp_uid], expires: 1.hour.from_now)
      end
    else
      cable_urls[:url] = new_thumb[:url]
      cable_urls[:webp_url] = new_thumb[:webp_url]
    end

    ActionCable.server.broadcast(FolioThumbnailsChannel::STREAM,
      temporary_url: image.temporary_url(size),
      temporary_s3_url: image.temporary_s3_url(size),
      url: cable_urls[:url],
      webp_url: cable_urls[:webp_url],
      width: new_thumb[:width],
      height: new_thumb[:height],
    )

    image
  end

  private
    def make_thumb(image, size, quality, x: nil, y: nil)
      make_webp = false

      if /png/.match?(image.try(:mime_type))
        if Rails.application.config.folio_dragonfly_keep_png
          thumbnail = image_file(image).thumb(size, format: :png, x: x, y: y)
        else
          thumbnail = image_file(image).add_white_background
                                       .thumb(size, format: :jpg, x: x, y: y)
                                       .encode("jpg", "-quality #{quality}")
                                       .jpegoptim
        end

        make_webp = true
      elsif image.animated_gif?
        thumbnail = image_file(image).animated_gif_resize(size)
      elsif /pdf/.match?(image.try(:mime_type))
        # "frame" option has to be set as string key
        # https://github.com/markevans/dragonfly/issues/483
        thumbnail = image_file(image).add_white_background
                                     .thumb(size, format: :jpg, "frame" => 0, x: x, y: y)
                                     .encode("jpg", "-quality #{quality}")
                                     .jpegoptim
      else
        thumbnail = image_file(image).thumb(size, format: :jpg, x: x, y: y)
                                     .auto_orient
                                     .encode("jpg", "-quality #{quality}")
                                     .cmyk_to_srgb
                                     .jpegoptim

        make_webp = true
      end

      if opts = image.try(:thumbnail_store_options)
        if opts[:path]
          opts[:path] += "/#{size}/#{thumbnail.name}"
        end

        uid = thumbnail.store(opts)
        is_private = !!opts[:private]
      else
        uid = thumbnail.store
        is_private = false
      end

      base = {
        uid: uid,
        signature: thumbnail.signature,
        url: Dragonfly.app.datastore.url_for(uid),
        width: thumbnail.width,
        height: thumbnail.height,
        quality: quality,
        x: x,
        y: y,
        private: is_private,
      }

      if make_webp
        webp = thumbnail.convert_to_webp
        webp.name = Pathname(webp.name).sub_ext(".webp").to_s

        if opts = image.try(:thumbnail_store_options)
          if opts[:path]
            opts[:path] += "/#{size}/#{webp.name}"
          end

          webp_uid = webp.store(opts)
        else
          webp_uid = webp.store
        end

        base.merge(
          webp_uid: webp_uid,
          webp_url: Dragonfly.app.datastore.url_for(webp_uid),
          webp_signature: webp.signature,
        )
      else
        base
      end
    end

    def image_file(image)
      if Rails.env.development? && ENV["DEV_S3_DRAGONFLY"] && ENV["DRAGONFLY_PRODUCTION_S3_URL_BASE"] && image.respond_to?(:development_safe_file)
        image.development_safe_file(logger)
      else
        image.file
      end
    end
end
