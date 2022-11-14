# frozen_string_literal: true

class AddRolesToAccount < ActiveRecord::Migration[7.0]
  def up
    add_column :folio_accounts, :roles, :jsonb, default: []

    say_with_time "converting account roles" do
      Folio::Account.find_each do |account|
        account.update_column(:roles, [account.role]) if account.role.present?
      end
    end

    remove_column :folio_accounts, :role
  end

  def down
    add_column :folio_accounts, :role, :string

    say_with_time "reverting account roles" do
      Folio::Account.find_each do |account|
        account.update_column(:role, account.roles.first || "manager")
      end
    end

    remove_column :folio_accounts, :roles
  end
end
