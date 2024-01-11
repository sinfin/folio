# frozen_string_literal: true

class Dummy::Molecule::Cards::MediumComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "240x320#"
  MOBILE_THUMB_SIZE = "480x396#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def card_tag(atom)
    base_class = "d-molecule-cards-medium__card"
    tag = { tag: :div, class: base_class }

    if atom.url.present?
      tag[:class] += " #{base_class}--link d-ui-image-hover-zoom-wrap"
    end

    if atom.cover_placement.present?
      tag[:class] += " #{base_class}--cover"
    end

    tag
  end

  def link_with_fallback_tag(atom)
    base_class = "d-molecule-cards-medium__card-link"

    if atom.url.present?
      { tag: :a, href: atom.url, class: base_class }
    else
      {}
    end
  end
end
