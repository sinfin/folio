# frozen_string_literal: true

class AddSourceSiteRelationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :folio_users, :source_site
  end
end
