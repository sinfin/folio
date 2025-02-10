# frozen_string_literal: true

class Folio::Atom::Audited::InvalidComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def render?
    @atom_options && @atom_options[:console_preview]
  end
end
