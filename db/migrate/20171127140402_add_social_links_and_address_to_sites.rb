# frozen_string_literal: true

class AddSocialLinksAndAddressToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_sites, :social_links, :json
    add_column :folio_sites, :address, :text
  end
end
