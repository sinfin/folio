# frozen_string_literal: true

class AddAuthSiteToFolioUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :folio_users, :auth_site, null: false, foreign_key: { to_table: :folio_sites }, default: Folio.main_site.id
  end
end
