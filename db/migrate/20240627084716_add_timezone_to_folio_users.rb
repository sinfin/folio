# frozen_string_literal: true

class AddTimezoneToFolioUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_users, :time_zone, :string, default: Rails.configuration.time_zone
  end
end
