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
                        :small,
                        :cloned,
                        :round,
                        :static?

  def show
    render if size
  end

  def data
    return nil unless model.present?

    @data ||= begin
      if static?
        use_webp = model[:webp_normal] && model[:webp_retina]
        {
          alt: "",
          src: model[:normal],
          srcset: model[:retina] ? "#{model[:normal]} 1x, #{model[:retina]} #{retina_multiplier}x" : nil,
          webp_src: model[:webp_normal],
          webp_srcset: use_webp ? "#{model[:webp_normal]} 1x, #{model[:webp_retina]} #{retina_multiplier}x" : nil,
          use_webp: use_webp,
        }
      else
        if model.is_a?(Folio::FilePlacement::Base)
          file = model.file
        else
          file = model
        end

        retina_size = size.gsub(/\d+/) { |n| n.to_i * retina_multiplier }

        normal = file.thumb(size)
        retina = file.thumb(retina_size)

        use_webp = normal[:webp_url] && retina[:webp_url]

        h = {
          normal: normal,
          retina: retina,
          alt: model.try(:alt) || "",
          title: model.try(:title),
          use_webp: use_webp,
          src: normal.url,
          srcset: "#{normal.url} 1x, #{retina.url} #{retina_multiplier}x",
        }

        if use_webp
          h[:webp_src] = normal.webp_src
          h[:webp_srcset] = "#{normal.webp_url} 1x, #{retina.webp_url} #{retina_multiplier}x"
        end

        h
      end
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
      if options[:max_height]
        width = (options[:max_height] / spacer_ratio).round(4)
      else
        width = options[:max_width] || size.split("x").first
      end

      if width.present?
        width = "#{width}px" unless width.to_s.match?(/%|none/)
        styles << "max-width: #{width}"
      end
    end

    styles.join(";")
  end

  def spacer_style
    s = ""

    if options[:spacer_background]
      if options[:spacer_background].is_a?(String)
        s += "background-color: #{options[:spacer_background]};"
      elsif options[:spacer_background] == false
        s += "background-color: transparent;"
      elsif options[:spacer_background] == true
        img = model
        img = model.file if model.is_a?(Folio::FilePlacement::Base)
        s += "background-color: #{img.additional_data['dominant_color']};"
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
    }

    if options[:href]
      h[:tag] = :a
      h[:href] = options[:href]
    elsif model && lightboxable?
      if model.is_a?(Folio::FilePlacement::Base)
        h = h.merge(lightbox(model))
        h["data-lightbox-title"] ||= options[:title] || model.try(:title)
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
end
