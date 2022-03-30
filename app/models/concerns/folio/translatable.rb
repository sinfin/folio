# frozen_string_literal: true

module Folio::Translatable
  extend ActiveSupport::Concern

  included do
    belongs_to :original, class_name: self.name,
                          foreign_key: :original_id,
                          optional: true

    has_many :translations, class_name: self.name,
                            foreign_key: :original_id,
                            inverse_of: :original,
                            dependent: :destroy

    validates :locale,
              presence: true,
              inclusion: { in: proc { I18n.available_locales.map(&:to_s) } }

    validates :locale,
              uniqueness: { scope: :original_id },
              if: :original_id

    before_validation do
      if locale.nil?
        if Rails.application.config.folio_site_is_a_singleton && Folio::Site.exists?
          self.locale = Folio::Site.instance.locale
        else
          self.locale = I18n.locale
        end
      end
    end

    scope :original, -> { where(original_id: nil) }
    scope :by_locale, -> (locale) { where(locale:)   }
  end

  # TODO
  def translate(locale)
    return nil unless persisted?
    existing = translation(locale)
    return existing if existing.present?

    translation = dup
    translation.locale = locale
    translation.original_id = id
    translation.published = false

    # Files
    file_placements.find_each do |fp|
      translation.file_placements << fp.dup
    end

    # Atoms
    atoms.find_each do |atom|
      atom_translation = atom.dup
      atom.file_placements.find_each do |fp|
        atom_translation.file_placements << fp.dup
      end
      translation.atoms << atom_translation
    end

    translation
  end

  def translate!(locale)
    ActiveRecord::Base.transaction do
      translation = translate(locale)
      translation.save!
      translation
    end
  end

  def translation?
    original.present?
  end

  def translation(locale = I18n.locale)
    translations.find_by(locale:)
  end
end
