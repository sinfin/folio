# frozen_string_literal: true

class AddSuperadminToFolioUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_users, :superadmin, :boolean, default: false, null: false
  end
end
