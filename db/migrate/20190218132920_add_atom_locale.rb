# frozen_string_literal: true

class AddAtomLocale < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_atoms, :locale, :string, index: true

    if Rails.application.config.folio_using_traco
      Folio::Atom::Base.find_each do |atom|
        atom.update_column(:locale, I18n.default_locale)

        (I18n.available_locales - [I18n.default_locale]).each do |locale|
          translation = atom.dup
          translation.locale = locale
          atom.file_placements.find_each do |fp|
            translation.file_placements << fp.dup
          end

          translation["title_#{I18n.default_locale}"] = translation["title_#{locale}"]
          translation["perex_#{I18n.default_locale}"] = translation["perex_#{locale}"]
          translation["content_#{I18n.default_locale}"] = translation["content_#{locale}"]

          translation.save!
        end

        (I18n.available_locales - [I18n.default_locale]).each do |locale|
          %i[title perex content].each do |field|
            column = "#{field}_#{locale}".to_sym
            if column_exists?(:folio_atoms, column)
              remove_column :folio_atoms, column
            end
          end
        end

        %i[title perex content].each do |field|
          column = "#{field}_#{I18n.default_locale}".to_sym
          if column_exists?(:folio_atoms, column)
            rename_column :folio_atoms, column, field
          end
        end
      end
    end
  end
end
