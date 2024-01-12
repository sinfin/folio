# frozen_string_literal: true

class Dummy::Atom::Images::SingleComponent < ApplicationComponent
  THUMB_SIZE = "1184x850"

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end
end
