# frozen_string_literal: true

class Dummy::Atom::DividerComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def variant_class_name
    "d-atom-divider--#{@atom.variant_with_fallback}"
  end

  def margin_class_name
    "d-atom-divider--margin-#{@atom.margin_with_fallback}"
  end
end
