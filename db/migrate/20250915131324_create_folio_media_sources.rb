# frozen_string_literal: true

class CreateFolioMediaSources < ActiveRecord::Migration[8.0]
  def change
    create_table :folio_media_sources do |t|
      t.string :title, null: false
      t.string :licence
      t.string :copyright_text

      t.integer :max_usage_count, default: 1

      t.references :site, null: false, foreign_key: { to_table: :folio_sites }

      t.timestamps
    end

    add_index :folio_media_sources, :title

    create_table :folio_media_source_site_links do |t|
      t.references :media_source, null: false, foreign_key: { to_table: :folio_media_sources }
      t.references :site, null: false, foreign_key: { to_table: :folio_sites }

      t.timestamps
    end

    add_index :folio_media_source_site_links, [:media_source_id, :site_id], unique: true, name: "index_folio_media_source_site_links_unique"

    add_reference :folio_files, :media_source, null: true, foreign_key: { to_table: :folio_media_sources }
    add_column :folio_files, :attribution_max_usage_count, :integer

    create_table :folio_file_site_links do |t|
      t.references :file, null: false, foreign_key: { to_table: :folio_files }
      t.references :site, null: false, foreign_key: { to_table: :folio_sites }

      t.timestamps
    end

    add_index :folio_file_site_links, [:file_id, :site_id], unique: true, name: "index_folio_file_site_links_unique"
  end
end
