# frozen_string_literal: true

class Dummy::Atom::ImageAndContentComponent < ApplicationComponent
  THUMB_SIZE = "648x450#"

  bem_class_name :image_right, :with_link

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    @image_right = @atom.image_side_with_fallback == "right"
    @with_link = @atom.url.present?
  end

  def data
    stimulus_lightbox if @atom.url.blank?
  end
end
