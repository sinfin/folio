# frozen_string_literal: true

class Dummy::Molecule::Cards::LargeComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "424x420#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def card_tag(atom)
    base_class = "d-molecule-cards-large__card"
    tag = { tag: :div, class: base_class }

    if atom.button_url.present?
      tag[:class] += " #{base_class}--link"
    end

    tag
  end
end
