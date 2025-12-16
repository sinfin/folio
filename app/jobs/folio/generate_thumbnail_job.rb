# frozen_string_literal: true

class Folio::GenerateThumbnailJob < Folio::ApplicationJob
  queue_as :slow

  discard_on(ActiveJob::DeserializationError)

  unique :until_and_while_executing

  def perform(image, size, quality, x: nil, y: nil, force: false)
    return if image.file_mime_type.include?("svg")

    # need to reload here because of parallel jobs
    image.reload

    thumbnail_sizes = image.thumbnail_sizes || {}
    present_uid = thumbnail_sizes[size] && thumbnail_sizes[size][:uid]
    return if !force && present_uid

    Dragonfly.app.datastore.destroy(present_uid) if present_uid

    new_thumb = make_thumb(image, size, quality, x:, y:)

    # need to reload here because of parallel jobs
    image.reload.with_lock do
      thumbnail_sizes = image.thumbnail_sizes || {}
      image.dont_run_after_save_jobs = true
      image.thumbnail_sizes = thumbnail_sizes.merge(size => new_thumb)
      image.save!(validate: false)
    end

    MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                       {
                         type: "Folio::GenerateThumbnailJob",
                         data: {
                           id: image.id,
                           size: size,
                           temporary_url: image.temporary_url(size),
                           url: new_thumb[:url],
                           webp_url: new_thumb[:webp_url],
                           width: new_thumb[:width],
                           height: new_thumb[:height],
                           thumb: new_thumb,
                         }
                       }.to_json

    broadcast_file_update(image)

    image
  end

  # Define what makes a job unique - only image ID and size matter for deduplication
  # This prevents duplicate jobs for same thumbnail with different quality/force/x/y values
  def lock_key_arguments
    # For ActiveJob, arguments are: [image, size, quality, { x: nil, y: nil, force: false }]
    # We only want to use image and size for uniqueness
    image, size = arguments[0], arguments[1]

    # Handle both direct objects and GlobalID serialized objects
    if image.respond_to?(:to_global_id)
      [image.to_global_id.to_s, size]
    elsif image.is_a?(Hash) && image["_aj_globalid"]
      [image["_aj_globalid"], size]
    else
      # Fallback - use first two arguments
      [image, size]
    end
  end

  private
    def make_thumb(image, raw_size, quality, x: nil, y: nil)
      gravity = nil

      if raw_size.ends_with?("#")
        gravity = case image.try(:default_gravity)
                  when "east"
                    "e"
                  when "north"
                    "n"
                  when "south"
                    "s"
                  when "west"
                    "w"
                  else
                    "c"
        end

        size = "#{raw_size}#{gravity}"
      else
        size = raw_size
      end

      make_webp = true
      add_white_background = false
      format = :jpg

      if image.try(:file_mime_type) == "image/png"
        if Rails.application.config.folio_dragonfly_keep_png
          format = :png
          add_white_background = false
        else
          add_white_background = true
        end
      elsif image.try(:file_mime_type) == "image/gif"
        format = :jpg
        add_white_background = true
      elsif image.try(:file_mime_type) == "application/pdf"
        # TODO frame
        add_white_background = true
      end

      thumbnail = image_file(image)
      geometry = size

      if size.include?("#")
        _m, crop_width_f, crop_height_f = size.match(/(\d+)x(\d+)/).to_a.map(&:to_f)

        # Check for stored thumbnail configuration if x and y are nil
        if x.nil? && y.nil? && image.respond_to?(:thumbnail_configuration) && image.thumbnail_configuration.present?
          # Simplify the ratio (e.g., 16:9, 4:3, 1:1)
          gcd = crop_width_f.to_i.gcd(crop_height_f.to_i)
          ratio = "#{(crop_width_f.to_i / gcd)}:#{(crop_height_f.to_i / gcd)}"

          if image.thumbnail_configuration["ratios"].present? &&
             image.thumbnail_configuration["ratios"][ratio].present? &&
             image.thumbnail_configuration["ratios"][ratio]["crop"].present?
            crop_config = image.thumbnail_configuration["ratios"][ratio]["crop"]
            x = crop_config["x"].to_f if crop_config["x"].is_a?(Numeric)
            y = crop_config["y"].to_f if crop_config["y"].is_a?(Numeric)
          end
        end

        # Use thumbnail dimensions instead of stored dimensions to handle fallback images
        thumbnail_width = thumbnail.width || image.file_width || 0
        thumbnail_height = thumbnail.height || image.file_height || 0

        if crop_width_f > thumbnail_width || crop_height_f > thumbnail_height || !x.nil? || !y.nil?
          thumbnail = thumbnail.thumb("#{crop_width_f.to_i}x#{crop_height_f.to_i}^", format:)
        end

        if !x.nil? || !y.nil?
          # Use thumbnail dimensions if image was resized, otherwise use original dimensions
          current_width_f = thumbnail.width.to_f
          current_height_f = thumbnail.height.to_f

          fill_width_f = if current_width_f / current_height_f > crop_width_f / crop_height_f
            # current is wider than the required thumb rectangle -> reduce height
            current_width_f * crop_height_f / current_height_f
          else
            # current is narrower than the required crop rectangle -> reduce width
            crop_width_f
          end

          fill_height_f = fill_width_f * current_height_f / current_width_f

          x_px = [((x || 0) * fill_width_f.ceil).floor, fill_width_f.floor - crop_width_f].min
          y_px = [((y || 0) * fill_height_f.ceil).floor, fill_height_f.floor - crop_height_f].min

          safe_x_px = [x_px.floor, 0].max
          safe_y_px = [y_px.floor, 0].max

          geometry = "#{crop_width_f.to_i}x#{crop_height_f.to_i}+#{safe_x_px}+#{safe_y_px}"
        end
      end

      if add_white_background
        format = :jpg
        thumbnail = thumbnail.encode("jpg", output_options: { background: 255 })
        thumbnail.meta["mime_type"] = "image/jpeg"
      end

      thumbnail = thumbnail.thumb(geometry, format:)
      thumbnail = thumbnail.convert_grayscale_to_srgb(format:) if image.jpg? && format == :jpg
      thumbnail = thumbnail.normalize_profiles_via_liblcms2 if image.jpg? && format == :jpg
      thumbnail = thumbnail.jpegoptim if format == :jpg

      thumbnail

      if image.file_name
        case format.to_sym
        when :jpg
          thumbnail.name = image.file_name.gsub(/\.\w+\z/, ".jpg")
        when :png
          thumbnail.name = image.file_name.gsub(/\.\w+\z/, ".png")
        when :gif
          thumbnail.name = image.file_name.gsub(/\.\w+\z/, ".gif")
        else
          thumbnail.name = image.file_name
        end
      end

      if opts = image.try(:thumbnail_store_options)
        if path_base = opts.delete(:path_base)
          opts[:path] = "#{path_base}/#{size_for_s3_path(size)}/#{thumbnail.name}"
        end

        uid = thumbnail.store(opts)
        is_private = !!opts[:private]
      else
        uid = thumbnail.store
        is_private = false
      end

      # fix dragonfly content mime type after converting
      # otherwise image_properties (width/height) break
      # keep the string key!
      thumbnail.content.add_meta("mime_type" => thumbnail.mime_type)

      base = {
        uid:,
        signature: thumbnail.signature,
        url: Folio::S3.url_rewrite(Dragonfly.app.datastore.url_for(uid)),
        width: thumbnail.width,
        height: thumbnail.height,
        quality:,
        x:,
        y:,
        private: is_private,
        gravity:,
      }

      if make_webp
        webp = thumbnail.convert_to_webp
        webp.name = Pathname(webp.name).sub_ext(".webp").to_s

        if opts = image.try(:thumbnail_store_options)
          if path_base = opts.delete(:path_base)
            opts[:path] = "#{path_base}/#{size_for_s3_path(size)}/#{webp.name}"
          end

          webp_uid = webp.store(opts)
        else
          webp_uid = webp.store
        end

        base.merge(
          webp_uid:,
          webp_url: Folio::S3.url_rewrite(Dragonfly.app.datastore.url_for(webp_uid)),
          webp_signature: webp.signature,
        )
      else
        base
      end
    end

    def image_file(image)
      if Rails.env.development? && ENV["DRAGONFLY_PRODUCTION_S3_URL_BASE"] && image.respond_to?(:development_safe_file)
        thumbnail = image.development_safe_file(logger)
      else
        thumbnail = image.file
      end

      if image.class.human_type == "video"
        thumbnail = thumbnail.ffmpeg_screenshot_to_jpg(image.screenshot_time_in_ffmpeg_format)
        thumbnail.name = Pathname.new(image.file_name).sub_ext(".jpg")
        thumbnail.meta["mime_type"] = "image/jpeg"
      else
        thumbnail.name = image.file_name
        thumbnail.meta["mime_type"] = image.file_mime_type
      end

      thumbnail
    rescue Dragonfly::Job::Fetch::NotFound
      missing_image_path = Folio::Engine.root.join("data/images/missing-image.png")
      thumbnail = Dragonfly.app.create(File.binread(missing_image_path))
      thumbnail.name = image.file_name || "missing-image.png"
      thumbnail.meta["mime_type"] = "image/png"
      thumbnail
    end

    def size_for_s3_path(size)
      size.tr("#", "H")
          .gsub(">", "GT")
          .gsub("<", "LT")
          .gsub(/\W/, "")
    end
end
