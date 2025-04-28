# frozen_string_literal: true

class AddUsersLockable < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_users, :failed_attempts, :integer, default: 0, null: false
    add_column :folio_users, :unlock_token, :string
    add_column :folio_users, :locked_at, :datetime
  end
end
