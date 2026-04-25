# frozen_string_literal: true

class AddAiSettingsToFolioSites < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_sites, :ai_settings, :jsonb, default: {}, null: false
    add_index :folio_sites, :ai_settings, using: :gin
  end
end
