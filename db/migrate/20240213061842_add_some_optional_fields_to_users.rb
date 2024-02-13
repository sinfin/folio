# frozen_string_literal: true

class AddSomeOptionalFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_users, :degree_pre, :string, limit: 32
    add_column :folio_users, :degree_post, :string, limit: 32

    add_column :folio_users, :phone_secondary, :string

    add_column :folio_users, :born_at, :date

    add_column :folio_users, :bank_account_number, :string
  end
end
