# frozen_string_literal: true

class Dummy::Molecule::Cards::ImageComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  bem_class_name :padded

  THUMB_SIZE = "648x466^"

  def initialize(atoms:, atom_options: {}, padded: false)
    @atoms = atoms
    @atom_options = atom_options
    @padded = padded
  end
end
