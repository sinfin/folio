# frozen_string_literal: true

module Folio::HasAtoms
  extend ActiveSupport::Concern

  included do
    has_many :atoms, -> { ordered }, class_name: 'Folio::Atom::Base',
                                     as: :placement,
                                     inverse_of: :placement,
                                     dependent: :destroy

    accepts_nested_attributes_for :atoms, reject_if: :all_blank,
                                          allow_destroy: true
  end

  def atoms_in_molecules
    Folio::Atom.atoms_in_molecules(atoms)
  end
end
