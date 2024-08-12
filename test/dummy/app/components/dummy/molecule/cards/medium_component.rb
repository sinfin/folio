# frozen_string_literal: true

class Dummy::Molecule::Cards::MediumComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def cards
    @atoms.map do |atom|
      {
        title: atom.title,
        html: atom.content,
        href: atom.url,
        image: molecule_cover_placement(atom),
        size: :m,
        orientation: :horizontal,
        border: false,
      }
    end
  end
end
