# frozen_string_literal: true

class Dummy::Molecule::Cards::FullWidthComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "1920x1080#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end
end
