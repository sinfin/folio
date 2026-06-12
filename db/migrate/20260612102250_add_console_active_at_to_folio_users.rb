# frozen_string_literal: true

class AddConsoleActiveAtToFolioUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_users, :console_active_at, :datetime
    add_index :folio_users, :console_active_at
  end
end
