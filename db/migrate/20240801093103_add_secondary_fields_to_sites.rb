# frozen_string_literal: true

class AddSecondaryFieldsToSites < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_sites, :phone_secondary, :string
    add_column :folio_sites, :address_secondary, :text
  end
end
