# frozen_string_literal: true

class Dummy::Ui::HeroComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  ALLOWED_IMAGE_SIZES = %w[container full_width small medium large extra_large]
  ALLOWED_THEMES = %w[light dark]
  ALLOWED_OVERLAYS = [nil, "light", "dark"]

  THUMB_SIZES = {
    background: "2560x1440#",
    full_width: "1920x470#",
    container: "1320x470#",
    extra_large: "930x400#",
    large: "700x300#",
    medium: "400x200#",
    small: "100x100#",
  }

  MOBILE_THUMB_SIZES = {
    container: "648x350#",
  }

  bem_class_name :show_divider,
                 :top_spacing,
                 :contained_image,
                 :theme_light,
                 :theme_dark,
                 :background_overlay_light,
                 :background_overlay_dark

  def initialize(title: nil,
                 perex: nil,
                 date: nil,
                 author: nil,
                 cover: nil,
                 background_cover: nil,
                 image_size: ALLOWED_IMAGE_SIZES.first,
                 theme: ALLOWED_THEMES.first,
                 background_overlay: ALLOWED_OVERLAYS.first,
                 background_color: nil,
                 show_divider: false)

    @title = title
    @perex = perex
    @date = date
    @author = author
    @cover = cover
    @background_cover = background_cover
    @background_color = background_color
    @show_divider = show_divider

    @image_size = set_allowed_option(:image_size, image_size, ALLOWED_IMAGE_SIZES)
    @theme = set_allowed_option(:theme, theme, ALLOWED_THEMES)
    @background_overlay = set_allowed_option(:background_overlay, background_overlay, ALLOWED_OVERLAYS)

    @top_spacing = %w[full_width container].exclude?(@image_size)
    @theme_light = true if @theme == "light"
    @theme_dark = true if @theme == "dark"
    @background_color_light = true if @background_color == "light"
    @background_color_dark = true if @background_color == "dark"
  end

  def atom_styles
    "background-color: #{@background_color};" if @background_color.present?
  end

  def cover_tag
    @cover_tag ||= begin
      images = []

      if @cover.present?
        img_class_name = "d-ui-hero__image"

        if @image_size == "container"
          img_class_name += " d-ui-hero__image--contained"
        end

        if mobile_thumb_size.present?
          images << dummy_ui_image(@cover,
                                   mobile_thumb_size,
                                   class_name: "#{img_class_name} d-ui-hero__image--mobile")
        end

        images << dummy_ui_image(@cover,
                                 thumb_size,
                                 class_name: img_class_name)
      end

      if images.present?
        class_name = "d-ui-hero__cover-container"
        class_name = "container-fluid" if @image_size != "full_width"

        content_tag :div, images.join("").html_safe, class: class_name
      end
    end
  end

  def thumb_size
    @thumb_size ||= THUMB_SIZES[@image_size.to_sym]
  end

  def mobile_thumb_size
    @mobile_thumb_size ||= MOBILE_THUMB_SIZES[@image_size.to_sym]
  end

  def set_allowed_option(key, value, allowed)
    return value if allowed.include?(value)

    raise ArgumentError, "Unknown #{key}: #{value}"
  end
end
