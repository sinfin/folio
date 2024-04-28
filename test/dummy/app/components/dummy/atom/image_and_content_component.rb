# frozen_string_literal: true

class Dummy::Atom::ImageAndContentComponent < ApplicationComponent
  bem_class_name :image_right, :with_link, :centered_content, :background

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    @image_right = @atom.image_side_with_fallback == "right"
    @with_link = @atom.url.present?
    @thumb_size = @atom.thumb_size_with_fallback
    @background = @atom.wrapper_with_fallback == "background"
    @dark_mode = @atom.color_mode_with_fallback == "dark"
    @centered_content = @atom.vertically_centered_content
  end

  def data
    stimulus_lightbox if @atom.url.blank?
  end
end
