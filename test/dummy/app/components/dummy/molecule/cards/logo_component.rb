# frozen_string_literal: true

class Dummy::Molecule::Cards::LogoComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def card_tag(atom)
    tag = { tag: :div, class: "d-molecule-cards-logo__card" }

    if atom.url.present?
      tag.merge(tag: :a, href: atom.url)
    else
      tag
    end
  end
end
