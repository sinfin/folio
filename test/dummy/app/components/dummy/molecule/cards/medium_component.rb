# frozen_string_literal: true

class Dummy::Molecule::Cards::MediumComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "240x320#"
  MOBILE_THUMB_SIZE = "480x396#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end
end
