# frozen_string_literal: true

class AddCrossdomainDeviseDataToUsersAndAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_accounts, :crossdomain_devise_token, :string
    add_column :folio_accounts, :crossdomain_devise_set_at, :datetime
    add_index :folio_accounts, :crossdomain_devise_token

    add_column :folio_users, :crossdomain_devise_token, :string
    add_column :folio_users, :crossdomain_devise_set_at, :datetime
    add_index :folio_users, :crossdomain_devise_token
  end
end
