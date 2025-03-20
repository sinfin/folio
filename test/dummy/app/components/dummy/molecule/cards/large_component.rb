# frozen_string_literal: true

class Dummy::Molecule::Cards::LargeComponent < ApplicationComponent
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
        links: atom.link_url_json ? [atom.link_url_json] : nil,
        image: molecule_cover_placement(atom),
        size: :l,
        border: false,
      }

      if atom.button_url_json
        h[:button_label] = atom.button_url_json[:label]
        h[:rel] = atom.button_url_json[:rel]
        h[:target] = atom.button_url_json[:target]
        h[:href] = atom.button_url_json[:href]
      end

      h
    end
  end
end
