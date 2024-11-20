# frozen_string_literal: true

class AddConsolePathAttributesToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_accounts, :console_url, :string, index: true
    add_column :folio_accounts, :console_url_updated_at, :datetime
  end
end
