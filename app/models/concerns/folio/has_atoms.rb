# frozen_string_literal: true

module Folio::HasAtoms
  module Basic
    extend ActiveSupport::Concern

    included do
      has_many :atoms, -> { ordered },
                       class_name: 'Folio::Atom::Base',
                       as: :placement,
                       inverse_of: :placement,
                       dependent: :destroy

      accepts_nested_attributes_for :atoms,
                                    reject_if: :all_blank,
                                    allow_destroy: true
    end

    def atoms_in_molecules
      Folio::Atom.atoms_in_molecules(atoms)
    end

    def atom_image_placements
      Folio::Atom.atom_image_placements(atoms)
    end

    def all_atoms_in_array
      atoms.to_a
    end
  end

  module Localized
    extend ActiveSupport::Concern

    included do
      atom_locales.each do |locale|
        has_many "#{locale}_atoms".to_sym, -> { ordered.where(locale: locale) },
                                           class_name: 'Folio::Atom::Base',
                                           as: :placement,
                                           inverse_of: :placement,
                                           dependent: :destroy

        accepts_nested_attributes_for "#{locale}_atoms".to_sym,
                                      reject_if: :all_blank,
                                      allow_destroy: true
      end
    end

    class_methods do
      def atom_locales
        if Rails.application.config.folio_using_traco
          I18n.available_locales
        else
          [I18n.default_locale]
        end
      end
    end

    def all_atoms_in_array
      all = []
      self.class.atom_locales.each do |locale|
        all += atoms(locale).to_a
      end
      all
    end

    def atoms(locale = I18n.locale)
      send("#{locale}_atoms")
    end

    def atoms_in_molecules
      Folio::Atom.atoms_in_molecules(atoms)
    end

    def atom_image_placements
      atom_locales.map do |locale|
        Folio::Atom.atom_image_placements(send("#{locale}_atoms"))
      end.flatten
    end
  end
end
