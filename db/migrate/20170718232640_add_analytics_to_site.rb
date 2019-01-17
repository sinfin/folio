# frozen_string_literal: true

class AddAnalyticsToSite < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_sites, :google_analytics_tracking_code, :string, length: 32, default: nil
    add_column :folio_sites, :facebook_pixel_code, :string, length: 32, default: nil
  end
end
