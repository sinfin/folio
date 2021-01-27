# frozen_string_literal: true

class AddMenuItemStyleAndPageId < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_menu_items, :style, :string
    add_column :folio_menu_items, :folio_page_id, :integer

    unless reverting?
      Folio::MenuItem.where(target_type: "Folio::Page").each do |mi|
        mi.update_column(:folio_page_id, mi.target_id)
      end
    end
  end
end
