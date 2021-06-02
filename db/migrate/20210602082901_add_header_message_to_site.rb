# frozen_string_literal: true

class AddHeaderMessageToSite < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_sites, :header_message, :text
    add_column :folio_sites, :header_message_published, :boolean, default: false
    add_column :folio_sites, :header_message_published_from, :datetime
    add_column :folio_sites, :header_message_published_until, :datetime
  end
end
