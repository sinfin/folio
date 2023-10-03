# frozen_string_literal: true

class CreateFolioSiteUserLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :folio_site_user_links do |t|
      t.references :user, null: false, foreign_key: { to_table: :folio_users }
      t.references :site, null: false, foreign_key: { to_table: :folio_sites }
      t.json :roles, default: []

      t.timestamps
    end
  end
end
