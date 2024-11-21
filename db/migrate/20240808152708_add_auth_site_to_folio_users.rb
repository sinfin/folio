# frozen_string_literal: true

class AddAuthSiteToFolioUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :folio_users, :auth_site, null: true, foreign_key: { to_table: :folio_sites }
    execute "UPDATE folio_users SET auth_site_id = #{Folio::Current.main_site.id}" if Folio::User.any?
    change_column_null :folio_users, :auth_site_id, false
  end
end
