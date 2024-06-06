class Dummy::Atom::HeroComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

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

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options

    set_bem_class_variables
  end

  def atom_styles
    return unless @atom.background_color.present? &&
                  @atom.show_background_color == true

    "background-color: #{@atom.background_color};"
  end

  def cover_tag
    @cover_tag ||= begin
      images = []

      if @atom.cover_placement.present?
        img_class_name = "d-atom-hero__image"

        if @atom.image_size_with_fallback == "container"
          img_class_name += " d-atom-hero__image--contained"
        end

        if mobile_thumb_size.present?
          images << dummy_ui_image(atom_cover_placement(@atom),
                                   mobile_thumb_size,
                                   class_name: "#{img_class_name} d-atom-hero__image--mobile")
        end

        images << dummy_ui_image(atom_cover_placement(@atom),
                                 thumb_size,
                                 class_name: img_class_name)
      end

      class_name = "d-atom-hero__cover-container"
      class_name = "container-fluid" if @atom.image_size_with_fallback != "full_width"

      content_tag :div, images.join("").html_safe, class: class_name
    end
  end

  def thumb_size
    @thumb_size ||= THUMB_SIZES[@atom.image_size_with_fallback.to_sym]
  end

  def mobile_thumb_size
    @mobile_thumb_size ||= MOBILE_THUMB_SIZES[@atom.image_size_with_fallback.to_sym]
  end

  def cover_container_tag; end

  def set_bem_class_variables
    @show_divider = @atom.show_divider
    @top_spacing = %w[full_width container].exclude?(@atom.image_size_with_fallback)

    instance_variable_set("@theme_#{@atom.theme_with_fallback}", true)

    return unless @atom.background_overlay.present?

    instance_variable_set("@background_overlay_#{@atom.background_overlay}",
                          true)
  end
end
