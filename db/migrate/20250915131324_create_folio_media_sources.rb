# frozen_string_literal: true

class CreateFolioMediaSources < ActiveRecord::Migration[8.0]
  def change
    create_table :folio_media_sources do |t|
      t.string :title, null: false
      t.string :licence
      t.string :copyright_text

      t.integer :max_usage_count, default: 1
      t.integer :assigned_media_count, default: 0

      t.timestamps
    end

    add_index :folio_media_sources, :title

    create_table :folio_media_source_site_links do |t|
      t.references :media_source, null: false, foreign_key: { to_table: :folio_media_sources }
      t.references :site, null: false, foreign_key: { to_table: :folio_sites }

      t.timestamps
    end

    add_index :folio_media_source_site_links, [:media_source_id, :site_id], unique: true, name: "index_folio_media_source_site_links_unique"
  end
end
