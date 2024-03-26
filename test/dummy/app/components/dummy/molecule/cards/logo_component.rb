# frozen_string_literal: true

class Dummy::Molecule::Cards::LogoComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "64x64#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def card_tag(atom)
    base_class = "d-molecule-cards-logo__card"
    tag = { tag: :div, class: base_class }

    if atom.url.present?
      tag[:class] += " #{base_class}--link"
      tag.merge(tag: :a, href: atom.url)
    else
      tag
    end
  end

  def inline_logos
    @atoms.filter do |atom|
      !orphan_logos || orphan_logos.exclude?(atom)
    end
  end

  def orphan_logos
    return unless @atoms.size > 3

    @atoms[-2..-1]
  end
end
