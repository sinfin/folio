# frozen_string_literal: true

class Dummy::Molecule::Card::PaddedImageComponent < ApplicationComponent
  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end
end
