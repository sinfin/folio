# frozen_string_literal: true

class AddGoogleAnalyticsTrackingCodeV4ToSites < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_sites, :google_analytics_tracking_code_v4, :string
  end
end
