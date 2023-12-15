# frozen_string_literal: true

class AddDefaultToFolioSitesAvailableUserRoles < ActiveRecord::Migration[7.0]
  def up
    change_column :folio_sites, :available_user_roles, :json, default: %w[administrator manager]
  end

  def down
    change_column :folio_sites, :available_user_roles, :json, default: %w[]
  end
end
