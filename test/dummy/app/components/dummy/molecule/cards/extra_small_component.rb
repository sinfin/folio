# frozen_string_literal: true

class Dummy::Molecule::Cards::ExtraSmallComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "80x80#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def image_class
    "d-molecule-cards-extra-small__image"
  end
end
