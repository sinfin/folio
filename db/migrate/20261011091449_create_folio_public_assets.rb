# frozen_string_literal: true

class CreateFolioPublicAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :folio_public_assets do |t|
      t.references :site, null: false, foreign_key: { to_table: :folio_sites }
      t.references :created_by_folio_user, foreign_key: { to_table: :folio_users }
      t.uuid :token, null: false
      t.string :file_name, null: false
      t.string :file_mime_type, null: false
      t.bigint :file_size, null: false
      t.string :s3_key
      t.timestamps
    end
    add_index :folio_public_assets, :token, unique: true
  end
end
