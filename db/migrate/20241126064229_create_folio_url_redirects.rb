# frozen_string_literal: true

class CreateFolioUrlRedirects < ActiveRecord::Migration[7.1]
  def change
    create_table :folio_url_redirects do |t|
      t.string :title

      t.string :url_from
      t.string :url_to

      t.integer :status_code, default: 301

      t.boolean :published, default: true
      t.boolean :match_query, default: false
      t.boolean :pass_query, default: true

      t.belongs_to :site

      t.timestamps
    end
  end
end
