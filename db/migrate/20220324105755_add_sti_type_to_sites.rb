# frozen_string_literal: true

class AddStiTypeToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :type, :string
    add_index :folio_sites, :type
  end
end
