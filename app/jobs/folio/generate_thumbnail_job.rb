# frozen_string_literal: true

class Folio::GenerateThumbnailJob < Folio::ApplicationJob
  queue_as :default

  def perform(image, size, quality, x: nil, y: nil, force: false)
    return if /svg/.match?(image.file_mime_type)

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

    MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                       {
                         type: "Folio::GenerateThumbnailJob",
                         data: {
                           id: image.id,
                           temporary_url: image.temporary_url(size),
                           url: new_thumb[:url],
                           webp_url: new_thumb[:webp_url],
                           thumb_key: size,
                           thumb: new_thumb,
                         }
                       }.to_json

    image
  end

  private
    def make_thumb(image, raw_size, quality, x: nil, y: nil)
      size = raw_size.ends_with?("#") ? "#{raw_size}c" : raw_size

      if image.animated_gif?
        thumbnail = image_file(image).animated_gif_resize(size)
      else
        add_white_background = false
        format = :jpg
        make_webp = true

        if /png/.match?(image.try(:file_mime_type))
          if Rails.application.config.folio_dragonfly_keep_png
            format = :png
          else
            add_white_background = true
          end
        elsif /pdf/.match?(image.try(:file_mime_type))
          # TODO frame
          add_white_background = true
        end

        thumbnail = image_file(image)
        geometry = size

        if size.include?("#")
          _m, crop_width_f, crop_height_f = size.match(/(\d+)x(\d+)/).to_a.map(&:to_f)

          if crop_width_f > image.file_width || crop_height_f > image.file_height || !x.nil? || !y.nil?
            thumbnail = thumbnail.thumb("#{crop_width_f.to_i}x#{crop_height_f.to_i}^")
          end

          if !x.nil? || !y.nil?
            image_width_f = image.file_width.to_f
            image_height_f = image.file_height.to_f

            fill_width_f = if image_width_f / image_height_f > crop_width_f / crop_height_f
              # original is wider than the required thumb rectangle -> reduce height
              image_width_f * crop_height_f / image_height_f
            else
              # original is narrower than the required crop rectangle -> reduce width
              crop_width_f
            end

            fill_height_f = fill_width_f * image_height_f / image_width_f

            x_px = [((x || 0) * fill_width_f.ceil).floor, fill_width_f.floor - crop_width_f].min
            y_px = [((y || 0) * fill_height_f.ceil).floor, fill_height_f.floor - crop_height_f].min

            geometry = "#{crop_width_f.to_i}x#{crop_height_f.to_i}+#{x_px.floor}+#{y_px.floor}"
          end
        end

        thumbnail = thumbnail.thumb(geometry, format: format)
        thumbnail = thumbnail.add_white_background if add_white_background
        thumbnail = thumbnail.normalize_profiles_via_liblcms2 if image.jpg? && format == :jpg
        thumbnail = thumbnail.jpegoptim if format == :jpg

        thumbnail
      end

      thumbnail.name = image.file_name

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
