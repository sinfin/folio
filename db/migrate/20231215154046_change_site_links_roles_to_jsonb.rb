# frozen_string_literal: true

class ChangeSiteLinksRolesToJsonb < ActiveRecord::Migration[7.0]
  def up
    change_column :folio_site_user_links, :roles, :jsonb, default: %w[]
  end

  def down
    change_column :folio_site_user_links, :roles, :json, default: %w[]
  end
end
