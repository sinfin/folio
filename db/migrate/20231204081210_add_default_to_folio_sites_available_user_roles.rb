# frozen_string_literal: true

class AddDefaultToFolioSitesAvailableUserRoles < ActiveRecord::Migration[7.0]
  def change
    change_column :folio_sites, :available_user_roles, :json, default: %w[superuser administrator manager]
  end
end
