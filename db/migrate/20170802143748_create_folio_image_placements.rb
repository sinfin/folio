class CreateFolioImagePlacements < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_image_placements do |t|
      t.belongs_to :node
      t.belongs_to :image

      t.string :caption
      t.integer :position

      t.timestamps
    end
  end
end
