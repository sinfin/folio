# frozen_string_literal: true

class AddAvailableUserRolesToFolioSite < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :available_user_roles, :json, default: []
  end
end
