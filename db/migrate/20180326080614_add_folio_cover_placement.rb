class AddFolioCoverPlacement < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_cover_placements do |t|
      t.belongs_to :placement, polymorphic: true
      t.belongs_to :file

      t.timestamps
    end
  end
end
