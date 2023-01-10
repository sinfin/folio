# frozen_string_literal: true

class AddCopyrightInfoSourceToSite < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :copyright_info_source, :string
  end
end
