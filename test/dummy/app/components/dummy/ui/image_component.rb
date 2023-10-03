# frozen_string_literal: true

class Dummy::Ui::ImageComponent < ApplicationComponent
  bem_class_name :lightbox, :contain, :cover, :hover_zoom, :round

  RETINA_MULTIPLIER = 2

  def initialize(placement:,
                 size:,
                 lazy: true,
                 lightbox: false,
                 contain: false,
                 cover: false,
                 hover_zoom: false,
                 alt: nil,
                 title: nil,
                 cap_width: false,
                 style: nil,
                 spacer_background: true,
                 round: false,
                 additional_html: nil,
                 class_name: nil)
    @size = size
    @lightbox = lightbox
    @contain = contain
    @cover = cover
    @hover_zoom = hover_zoom
    @alt = alt
    @title = title
    @cap_width = cap_width
    @style = style
    @spacer_background = spacer_background || ::Rails.application.config.folio_image_spacer_background_fallback
    @additional_html = additional_html
    @class_name = class_name
    @round = round
    @data = set_data(placement)
  end

  def set_data(placement)
    return nil unless placement.present?

    if placement.is_a?(Hash)
      use_webp = placement[:webp_normal].present?

      if placement[:webp_normal].present?
        if placement[:webp_retina].present?
          webp_srcset = "#{placement[:webp_normal]} 1x, #{placement[:webp_retina]} #{RETINA_MULTIPLIER}x"
        else
          webp_srcset = placement[:webp_normal]
        end
      else
        webp_srcset = nil
      end

      @data = {
        alt: @alt || "",
        title: @title || "",
        src: placement[:normal],
        srcset: placement[:retina] ? "#{placement[:normal]} 1x, #{placement[:retina]} #{RETINA_MULTIPLIER}x" : nil,
        webp_src: placement[:webp_normal],
        webp_srcset:,
        use_webp:,
      }
    else
      if placement.is_a?(Folio::FilePlacement::Base)
        file = placement.file
      else
        file = placement
      end

      normal = file.thumb(@size)

      h = {
        file:,
        normal:,
        src: normal.url,
        alt: @alt || file.try(:alt) || file.try(:description) || "",
        title: @title,
        width: normal[:width],
        height: normal[:height],
        sensitive_content: file.try(:sensitive_content?) || false,
      }

      unless file.file_mime_type.include?("svg")
        retina_size = @size.gsub(/\d+/) { |n| n.to_i * RETINA_MULTIPLIER }

        retina = file.thumb(retina_size)

        use_webp = normal[:webp_url] && retina[:webp_url]

        h[:retina] = retina
        h[:use_webp] = use_webp
        h[:srcset] = "#{normal.url} 1x, #{retina.url} #{RETINA_MULTIPLIER}x"

        if use_webp
          h[:webp_src] = normal.webp_src
          h[:webp_srcset] = "#{normal.webp_url} 1x, #{retina.webp_url} #{RETINA_MULTIPLIER}x"
        end
      end

      @data = h
    end
  end

  def wrap_style
    return nil if @cover || @contain

    styles = []

    max_height = nil

    if thumbnail_width
      max_width = thumbnail_width
      max_height = "#{thumbnail_height}px" if thumbnail_height
    else
      max_width = @size.split("x").first
    end

    if max_width.present?
      unless max_width.to_s.match?(/%|none/)
        file = @data && @data[:file]

        if @cap_width && file.respond_to?(:file_width)
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

    styles << @style if @style.present?

    styles.join(";")
  end

  def spacer_style
    s = ""

    if @spacer_background
      if @spacer_background.is_a?(String)
        s += "background-color: #{@spacer_background};"
      elsif @spacer_background == false
        s += "background-color: transparent;"
      elsif @spacer_background == true
        img = @data && @data[:file]

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
      if @data && @data[:normal]
        width = @data[:normal].width
        height = @data[:normal].height
      else
        width, height = @size.split("x").map(&:to_i)
      end

      if width != 0 && height != 0
        height.to_f / width
      else
        0
      end
    end
  end

  def tag
    class_names = bem_class_name

    if @class_name
      class_names = "#{class_names} #{@class_name}"
    end

    h = {
      tag: :div,
      class: class_names,
      style: wrap_style,
      "data-width" => thumbnail_width,
      "data-height" => thumbnail_height,
    }

    if @href
      h[:tag] = :a
      h[:href] = @href
      # TODO lightbox
      # elsif model && lightboxable?
      #   if @lightbox.is_a?(Hash)
      #     h = h.merge(@lightbox)
      #   elsif model.is_a?(Folio::FilePlacement::Base)
      #     h = h.merge(lightbox(model))
      #     h["data-lightbox-caption"] = @title if @title
      #   else
      #     h = h.merge(lightbox_from_image(model))
      #   end
    end

    h
  end

  def self.fixed_height_mobile_ratio
    0.862
  end

  def self.fixed_height_default_width
    160
  end

  def thumbnail_size
    if @thumbnail_size.nil?
      if file = @data && @data[:file]
        t = file.thumb(@size)

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
end
