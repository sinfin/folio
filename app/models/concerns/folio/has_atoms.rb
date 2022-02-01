# frozen_string_literal: true

module Folio::HasAtoms
  module Commons
    extend ActiveSupport::Concern

    class_methods do
      def atom_settings_from_params(params)
        settings = {}

        settings = atom_settings_label_from_params(settings, params)
        settings = atom_settings_perex_from_params(settings, params)

        settings
      end

      def atom_settings_label_from_params(settings, params)
        if params[:label].present?
          params[:label].each do |locale, label|
            settings[locale] ||= []
            settings[locale] << {
              cell_name: "folio/console/atoms/previews/label",
              model: label,
              key: :label,
            }
          end
        end

        settings
      end

      def atom_settings_perex_from_params(settings, params)
        if params[:perex].present?
          params[:perex].each do |locale, perex|
            settings[locale] ||= []
            settings[locale] << {
              cell_name: "folio/console/atoms/previews/perex",
              model: perex,
              key: :perex,
            }
          end
        end

        settings
      end

      def atom_default_locale_from_params(params)
        # use the submitted locale for classes with a locale column
        if column_names.include?("locale") && locale = params[:locale].try(:[], :null)
          locale
        else
          I18n.default_locale
        end
      end
    end
  end

  module Basic
    extend ActiveSupport::Concern
    include Commons

    included do
      has_many :atoms, -> { ordered },
                       class_name: "Folio::Atom::Base",
                       as: :placement,
                       inverse_of: :placement,
                       dependent: :destroy

      accepts_nested_attributes_for :atoms,
                                    reject_if: :all_blank,
                                    allow_destroy: true
    end

    def atoms_in_molecules(includes: nil, includes_cover: false)
      if includes
        Folio::Atom.atoms_in_molecules(atoms.includes(*includes))
      elsif includes_cover
        Folio::Atom.atoms_in_molecules(atoms.includes(cover_placement: :file))
      else
        Folio::Atom.atoms_in_molecules(atoms)
      end
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
    include Commons

    included do
      atom_locales.each do |locale|
        has_many "#{locale}_atoms".to_sym, -> { ordered.where(locale: locale) },
                                           class_name: "Folio::Atom::Base",
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

    def atoms_in_molecules(includes: nil, includes_cover: false)
      if includes
        Folio::Atom.atoms_in_molecules(atoms.includes(*includes))
      elsif includes_cover
        Folio::Atom.atoms_in_molecules(atoms.includes(cover_placement: :file))
      else
        Folio::Atom.atoms_in_molecules(atoms)
      end
    end

    def atom_image_placements
      atom_locales.map do |locale|
        Folio::Atom.atom_image_placements(send("#{locale}_atoms"))
      end.flatten
    end
  end
end
