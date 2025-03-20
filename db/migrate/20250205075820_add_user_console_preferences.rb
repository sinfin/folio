# frozen_string_literal: true

class AddUserConsolePreferences < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_users, :console_preferences, :jsonb
  end
end
