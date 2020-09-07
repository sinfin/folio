# frozen_string_literal: true

class RmMenuItemSti < ActiveRecord::Migration[6.0]
  def change
    remove_column :folio_menu_items, :type
  end
end
