class CreateFolioMenuItems < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_menu_items do |t|
      t.belongs_to :menu
      t.belongs_to :node

      t.string :type, index: true
      t.string :ancestry, index: true
      t.string :title
      t.string :rails_path
      t.integer :position

      t.timestamps
    end
  end
end
