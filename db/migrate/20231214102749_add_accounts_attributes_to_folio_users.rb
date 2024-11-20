# frozen_string_literal: true

class AddAccountsAttributesToFolioUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_users, :console_path, :string
    add_column :folio_users, :console_path_updated_at, :datetime
  end
end
