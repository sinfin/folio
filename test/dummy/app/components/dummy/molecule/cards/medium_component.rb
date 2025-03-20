# frozen_string_literal: true

class Dummy::Molecule::Cards::MediumComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def cards
    @atoms.map do |atom|
      h = {
        title: atom.title,
        html: atom.content,
        image: molecule_cover_placement(atom),
        size: :m,
        orientation: :horizontal,
        border: false,
      }

      if atom.url_json.present?
        h[:href] = atom.url_json[:href]
        h[:target] = atom.url_json[:target]
        h[:rel] = atom.url_json[:rel]
        h[:link_title] = atom.url_json[:label]
      end

      h
    end
  end
end
