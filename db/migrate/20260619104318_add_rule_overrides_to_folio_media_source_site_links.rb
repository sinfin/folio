# frozen_string_literal: true

class AddRuleOverridesToFolioMediaSourceSiteLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_media_source_site_links, :licence, :string
    add_column :folio_media_source_site_links, :copyright_text, :string
    add_column :folio_media_source_site_links, :max_usage_count, :integer
  end
end
