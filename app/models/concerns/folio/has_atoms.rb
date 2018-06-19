# frozen_string_literal: true

module Folio
  module HasAtoms
    extend ActiveSupport::Concern

    included do
      has_many :atoms, -> { order(:position) }, class_name: 'Folio::Atom::Base',
                                                as: :placement,
                                                dependent: :destroy

      accepts_nested_attributes_for :atoms, reject_if: :all_blank,
                                            allow_destroy: true
    end

    def atoms_in_molecules
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
  end
end
