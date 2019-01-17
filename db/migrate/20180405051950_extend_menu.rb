# frozen_string_literal: true

class ExtendMenu < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_menus, :locale, :string

    add_reference :folio_menu_items, :target, polymorphic: true
    remove_reference :folio_menu_items, :node
  end
end
