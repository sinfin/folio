# frozen_string_literal: true

class CreateFolioCacheVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :folio_cache_versions do |t|
      t.belongs_to :site, null: false
      t.string :key, null: false
      t.datetime :expires_at
      t.jsonb :invalidation_metadata

      t.index [:site_id, :key], unique: true

      t.timestamps
    end
  end
end
