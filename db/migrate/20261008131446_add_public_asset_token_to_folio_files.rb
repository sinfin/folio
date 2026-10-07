# frozen_string_literal: true

class AddPublicAssetTokenToFolioFiles < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_files, :public_asset_token, :uuid
    add_index :folio_files, :public_asset_token, unique: true
  end
end
