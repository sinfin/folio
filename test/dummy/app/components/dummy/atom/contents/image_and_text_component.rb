# frozen_string_literal: true

class Dummy::Atom::Contents::ImageAndTextComponent < ApplicationComponent
  bem_class_name :image_right, :with_link, :vertically_centered_content, :background

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    @image_right = @atom.image_side == "right"
    @with_link = @atom.url_json.present? && @atom.url_json[:href].present?
    @thumb_size = @atom.thumb_size_with_fallback
    @wrapper = @atom.wrapper.present? && @atom.wrapper != "none"
    @background = @atom.wrapper == "background"
    @dark_mode = @atom.color_mode == "dark"
    @vertically_centered_content = @atom.vertically_centered_content
  end

  def data
    hash = @with_link ? {} : stimulus_lightbox

    if @dark_mode
      hash[:bs_theme] = "dark"
    end

    hash
  end

  def inner_narrow_container_class
    "container-fluid container-fluid--forced-padding container-narrow"
  end
end
