# frozen_string_literal: true

class Dummy::Molecule::Cards::LargeComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "424x420#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end
end
