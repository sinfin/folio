# frozen_string_literal: true

class Dummy::Atom::ImageAndContentComponent < ApplicationComponent
  THUMB_SIZE = "648x450#"

  bem_class_name :image_right

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    @image_right = @atom.image_side_with_fallback == "right"
  end
end
