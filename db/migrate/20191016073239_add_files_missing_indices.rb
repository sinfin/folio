# frozen_string_literal: true

class AddFilesMissingIndices < ActiveRecord::Migration[5.2]
  def change
    add_index :folio_files, :created_at
    add_index :folio_files, :file_name
    add_index :folio_files, :hash_id

    add_index :folio_file_placements, :placement_title
    add_index :folio_file_placements, :placement_title_type
  end
end
