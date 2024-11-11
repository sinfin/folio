# frozen_string_literal: true

class AddPreferredLocaleToFolioUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_users, :preferred_locale, :string
  end
end
