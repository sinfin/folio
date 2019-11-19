# frozen_string_literal: true

class ExtendMenuItem < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_menu_items, :url, :string
    add_column :folio_menu_items, :open_in_new, :boolean
  end
end
