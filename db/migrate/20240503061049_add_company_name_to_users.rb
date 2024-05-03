# frozen_string_literal: true

class AddCompanyNameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_users, :company_name, :string
  end
end
