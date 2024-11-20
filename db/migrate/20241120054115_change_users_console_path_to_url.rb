# frozen_string_literal: true

class ChangeUsersConsolePathToUrl < ActiveRecord::Migration[7.1]
  def change
    rename_column :folio_users, :console_url, :console_url
    rename_column :folio_users, :console_url_updated_at, :console_url_updated_at
  end
end
