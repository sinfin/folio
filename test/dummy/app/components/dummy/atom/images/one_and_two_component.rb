# frozen_string_literal: true

class Dummy::Atom::Images::OneAndTwoComponent < ApplicationComponent
  MAIN_THUMB_SIZE = "1045x655^"
  THUMB_SIZE = "275x315^"

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

  def thumb_size(i)
    i.zero? ? MAIN_THUMB_SIZE : THUMB_SIZE
  end
end
