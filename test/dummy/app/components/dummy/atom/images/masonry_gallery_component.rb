# frozen_string_literal: true

class Dummy::Atom::Images::MasonryGalleryComponent < ApplicationComponent
  THUMB_SIZE = "276x"

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def image_placements
    if @atom.persisted?
      @atom.image_placements.includes(:file)
    else
      @atom.image_placements
    end
  end
end
