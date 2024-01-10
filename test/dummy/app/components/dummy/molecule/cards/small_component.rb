# frozen_string_literal: true

class Dummy::Molecule::Cards::SmallComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "424x240#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def image_class_name
    "d-molecule-cards-small__card-image"
  end
end
