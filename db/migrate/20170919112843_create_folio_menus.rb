# frozen_string_literal: true

class CreateFolioMenus < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_menus do |t|
      t.string 'type', index: true

      t.timestamps
    end
  end
end
