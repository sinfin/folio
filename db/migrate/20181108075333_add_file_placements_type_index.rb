class AddFilePlacementsTypeIndex < ActiveRecord::Migration[5.2]
  def change
    unless index_exists?(:folio_file_placements, :type)
      add_index :folio_file_placements, :type
    end
  end
end
