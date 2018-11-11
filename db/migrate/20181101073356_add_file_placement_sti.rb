class AddFilePlacementSti < ActiveRecord::Migration[5.2]
  def up
    add_column :folio_file_placements, :type, :string
  end

  def down
    remove_column :folio_file_placements, :type
  end
end
