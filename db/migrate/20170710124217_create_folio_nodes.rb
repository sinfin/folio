# frozen_string_literal: true

class CreateFolioNodes < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_nodes do |t|
      t.integer "site_id", index: true

      t.string  "title"
      t.string  "slug", index: true
      t.text    "perex"
      t.text    "content"

      t.string  "meta_title", limit: 512
      t.string  "meta_description", limit: 1024

      t.string  "code", index: true
      t.string  "ancestry", index: true
      t.string  "type", index: true

      t.boolean  "featured", index: true
      t.integer  "position", index: true
      t.boolean  "published", index: true
      t.datetime "published_at", index: true

      t.integer "original_id", index: true
      t.string  :locale, limit: 6, index: true

      t.timestamps
    end
  end
end
