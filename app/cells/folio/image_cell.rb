# frozen_string_literal: true

class Folio::ImageCell < Folio::ApplicationCell
  include Folio::CellLightbox

  class_name 'f-image', :centered, :not_lazy?, :lightboxable?

  def show
    render if size
  end

  def data
    @data ||= begin
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
        alt: model.try(:alt) || '',
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
    width = options[:max_width] || size.split('x').first

    if width.present?
      width = "#{width}px" unless width.to_s.match?(/%|none/)
      "max-width: #{width}"
    end
  end

  def spacer_style
    if spacer_ratio != 0
      "padding-top: #{(100 * spacer_ratio).round(4)}%"
    end
  end

  def spacer_ratio
    if thumb
      width = thumb.width
      height = thumb.height
    else
      width, height = size.split('x').map(&:to_i)
    end

    if width != 0 && height != 0
      height.to_f / width
    else
      0
    end
  end

  def thumb
    if @thumb.nil?
      @thumb = model.try(:file).try(:thumb, size) || false
    else
      @thumb
    end
  end

  def size
    options[:size]
  end

  def tag
    class_names = class_name

    if options[:class]
      class_names = "#{class_names} #{options[:class]}"
    end

    h = {
      tag: :div,
      class: class_names,
      style: wrap_style,
    }

    if options[:href]
      h[:tag] = :a
      h[:href] = options[:href]
    elsif model && options[:lightbox]
      h = h.merge(lightbox(model))
      h['data-lightbox-title'] ||= options[:title] || model.try(:title)
    end

    h
  end

  def lightboxable?
    options[:lightbox]
  end
end
