# frozen_string_literal: true

class RemoveConsoleUrlFromFolioUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :folio_users, :console_url, :string
    remove_column :folio_users, :console_url_updated_at, :datetime
  end
end
