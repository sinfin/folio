# frozen_string_literal: true

class Dummy::Atom::QuotationComponent < ApplicationComponent
  bem_class_name :large

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    @large = @atom.large
  end
end
