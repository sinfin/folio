# frozen_string_literal: true

class AddSiteDescription < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_sites, :description, :text
  end
end
