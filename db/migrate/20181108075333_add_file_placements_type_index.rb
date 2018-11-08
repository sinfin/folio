class AddFilePlacementsTypeIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :folio_file_placements, :type
  end
end
