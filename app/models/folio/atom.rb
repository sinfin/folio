# frozen_string_literal: true

module Folio::Atom
  def self.types
    Folio::Atom::Base.recursive_subclasses
  end

  def self.atoms_in_molecules(atoms)
    molecules = []

    atoms.each_with_index do |atom, index|
      molecule = atom.class.molecule.presence ||
                 atom.class.molecule_cell_name.presence

      if index != 0 && molecule == molecules.last.first
        # same kind of molecule
        molecules.last.last << atom
      else
        # different kind of molecule
        molecules << [molecule, [atom]]
      end
    end

    molecules
  end

  def self.atoms_image_placements(atoms)
    images = []

    atoms.each do |atom|
      images << atom.image_placements
    end

    images
  end
end
