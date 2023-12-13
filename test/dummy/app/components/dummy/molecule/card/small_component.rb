# frozen_string_literal: true

class Dummy::Molecule::Card::SmallComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end
end
