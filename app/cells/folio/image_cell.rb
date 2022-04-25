# frozen_string_literal: true

class Folio::ImageCell < Folio::ApplicationCell
  include Folio::CellLightbox

  class_name "f-image", :centered,
                        :not_lazy?,
                        :lightboxable?,
                        :contain,
                        :cover,
                        :hover_zoom,
                        :fixed_height,
                        :fixed_height_fluid,
                        :cloned,
                        :round,
                        :static?,
                        :sensitive_content?,
                        :vertical_image?,
                        :custom_lightbox

  def show
    render if size
  end

  def data
    return nil unless model.present?

    @data ||= if static?
      use_webp = model[:webp_normal].present?

      if model[:webp_normal].present?
        if model[:webp_retina].present?
          webp_srcset = "#{model[:webp_normal]} 1x, #{model[:webp_retina]} #{retina_multiplier}x"
        else
          webp_srcset = model[:webp_normal]
        end
      else
        webp_srcset = nil
      end

      {
        alt: options[:alt] || "",
        src: model[:normal],
        srcset: model[:retina] ? "#{model[:normal]} 1x, #{model[:retina]} #{retina_multiplier}x" : nil,
        webp_src: model[:webp_normal],
        webp_srcset:,
        use_webp:,
      }
    else
      if model.is_a?(Folio::FilePlacement::Base)
        file = model.file
      else
        file = model
      end

      normal = file.thumb(size)

      h = {
        normal:,
        src: normal.url,
        alt: options[:alt] || "",
        title: options[:title],
      }

      unless /svg/.match?(file.file_mime_type)
        retina_size = size.gsub(/\d+/) { |n| n.to_i * retina_multiplier }

        retina = file.thumb(retina_size)

        use_webp = normal[:webp_url] && retina[:webp_url]

        h[:retina] = retina
        h[:use_webp] = use_webp
        h[:srcset] = "#{normal.url} 1x, #{retina.url} #{retina_multiplier}x"

        if use_webp
          h[:webp_src] = normal.webp_src
          h[:webp_srcset] = "#{normal.webp_url} 1x, #{retina.webp_url} #{retina_multiplier}x"
        end
      end

      h
    end
  end

  def retina_multiplier
    @retina_multiplier ||= options[:retina_multiplier] || 2
  end

  def not_lazy?
    options[:lazy] == false
  end

  def opts
    {
      lazyload_class: options[:lazyload_class],
      retina_multiplier: options[:retina_multiplier] || 2,
    }
  end

  def wrap_style
    styles = []

    if o = (options[:fixed_height_fluid] || options[:fixed_height])
      if data && data[:normal]
        desktop_height = data[:normal].height
        mobile_height = (data[:normal].height * self.class.fixed_height_mobile_ratio).round
      else
        desktop_height = o[:desktop]
        mobile_height = o[:mobile]
      end

      desktop = [
        data[:normal].try(:width) || fixed_height_default_width,
        o[:max_desktop_width],
      ].compact.min.round

      mobile = [
        (data[:normal].try(:width) || fixed_height_default_width) * self.class.fixed_height_mobile_ratio,
        o[:max_mobile_width]
      ].compact.min.round

      styles << "max-width: #{desktop}px"
      styles << "min-width: #{desktop}px"
      styles << "min-height: #{desktop_height}px"
      styles << "width: #{mobile}px"
      styles << "height: #{mobile_height}px"
    else
      max_height = nil

      if options[:max_height]
        max_width = (options[:max_height] / spacer_ratio).round(4)
      else
        if options[:max_width]
          max_width = options[:max_width]
        else
          if thumbnail_width
            max_width = thumbnail_width
            max_height = "#{thumbnail_height}px" if thumbnail_height
          else
            max_width = size.split("x").first
          end
        end
      end

      if max_width.present?
        unless max_width.to_s.match?(/%|none/)
          file = model

          if model.is_a?(Folio::FilePlacement::Base)
            file = model.file
          end

          if file.respond_to?(:file_width)
            max_width_i = max_width.to_i
            if max_width_i > 0
              if file.file_width
                max_width = [max_width_i, file.file_width].min
              else
                max_width = max_width_i
              end
            end
          end

          max_width = "#{max_width}px"
        end

        styles << "max-width: #{max_width}"
      end

      if max_height.present?
        styles << "max-height: #{max_height}"
      end

      if options[:fixed_width]
        styles << "width: #{options[:fixed_width]}"
      end
    end

    styles << options[:style] if options[:style].present?

    styles.join(";")
  end

  def spacer_style
    s = ""

    if spacer_background_option_with_default
      if spacer_background_option_with_default.is_a?(String)
        s += "background-color: #{spacer_background_option_with_default};"
      elsif spacer_background_option_with_default == false
        s += "background-color: transparent;"
      elsif spacer_background_option_with_default == true
        img = model
        img = model.file if model.is_a?(Folio::FilePlacement::Base)

        if img && img.try(:additional_data)
          s += "background-color: #{img.additional_data['dominant_color']};"
        end
      end
    end

    if spacer_ratio != 0
      s += "padding-top: #{(100 * spacer_ratio).round(4)}%;"
    end

    s
  end

  def spacer_ratio
    @spacer_ratio ||= begin
      if data && data[:normal]
        width = data[:normal].width
        height = data[:normal].height
      else
        width, height = size.split("x").map(&:to_i)
      end

      if width != 0 && height != 0
        height.to_f / width
      else
        0
      end
    end
  end

  def size
    options[:size]
  end

  def additional_class_names
    options[:class]
  end

  def tag
    class_names = class_name

    if additional_class_names
      class_names = "#{class_names} #{additional_class_names}"
    end

    h = {
      tag: :div,
      class: class_names,
      style: wrap_style,
      "data-width" => thumbnail_width,
      "data-height" => thumbnail_height,
    }

    if options[:href]
      h[:tag] = :a
      h[:href] = options[:href]
    elsif model && lightboxable?
      if options[:lightbox].is_a?(Hash)
        h = h.merge(options[:lightbox])
      elsif model.is_a?(Folio::FilePlacement::Base)
        h = h.merge(lightbox(model))
        h["data-lightbox-caption"] ||= options[:title]
      else
        h = h.merge(lightbox_from_image(model))
      end
    end

    h
  end

  def lightboxable?
    options[:lightbox]
  end

  def static?
    model.is_a?(Hash)
  end

  def self.fixed_height_mobile_ratio
    0.862
  end

  def self.fixed_height_default_width
    160
  end

  def spacer_background_option_with_default
    if options[:spacer_background].nil?
      ::Rails.application.config.folio_image_spacer_background_fallback
    else
      options[:spacer_background]
    end
  end

  def thumbnail_size
    if @thumbnail_size.nil?
      file = nil
      file = model if model.is_a?(Folio::File)
      file = model.file if model.is_a?(Folio::FilePlacement::Base)

      if file
        t = file.thumb(size)
        @thumbnail_size = {
          width: t.width,
          height: t.height,
        }
      else
        @thumbnail_size = false
      end
    else
      @thumbnail_size.presence
    end
  end

  def thumbnail_width
    if @thumbnail_width.nil?
      @thumbnail_width = thumbnail_size.try(:[], :width)
    else
      @thumbnail_width.presence
    end
  end

  def thumbnail_height
    if @thumbnail_height.nil?
      @thumbnail_height = thumbnail_size.try(:[], :height)
    else
      @thumbnail_height.presence
    end
  end

  def sensitive_content?
    return @sensitive_content unless @sensitive_content.nil?

    if model.is_a?(Folio::FilePlacement::Base)
      file = model.file
    else
      file = model
    end

    @sensitive_content = file.try(:sensitive_content?) || false
  end

  def vertical_image?
    if options[:always_keep_ratio] && self.thumbnail_width && self.thumbnail_height
      self.thumbnail_width < self.thumbnail_height
    end
  end

  def additional_html
  end
end
