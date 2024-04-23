# frozen_string_literal: true

class AddLockedAtToSiteLinks < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_site_user_links, :locked_at, :datetime, null: true, default: nil
  end
end
