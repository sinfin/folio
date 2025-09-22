# frozen_string_literal: true

class RenameFilePlacementsSizeToFilePlacementsCount < ActiveRecord::Migration[8.0]
  def change
    # Rename column and set proper defaults for counter cache
    rename_column :folio_files, :file_placements_size, :file_placements_count
    change_column_default :folio_files, :file_placements_count, 0
    change_column_null :folio_files, :file_placements_count, false, 0
  end
end
