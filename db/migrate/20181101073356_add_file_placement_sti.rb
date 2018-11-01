class AddFilePlacementSti < ActiveRecord::Migration[5.2]
  def up
    add_column :folio_file_placements, :type, :string, index: true

    Folio::FilePlacement.update_all(type: 'Folio::FilePlacement')
  end

  def down
    remove_column :folio_file_placements, :type
  end
end
