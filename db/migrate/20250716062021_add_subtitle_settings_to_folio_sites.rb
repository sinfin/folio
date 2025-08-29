# frozen_string_literal: true

class AddSubtitleSettingsToFolioSites < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_sites, :subtitle_languages, :jsonb, default: ["cs"]
    add_column :folio_sites, :subtitle_auto_generation_enabled, :boolean, default: false

    add_index :folio_sites, :subtitle_languages, using: :gin
  end
end
