# frozen_string_literal: true

class AddStiTypeAndSlugToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :type, :string
    add_index :folio_sites, :type

    add_column :folio_sites, :slug, :string
    add_index :folio_sites, :slug
  end
end
