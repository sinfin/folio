# frozen_string_literal: true

class AddFilesIndexAndCounter < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_files, :file_placements_size, :integer
    add_index :folio_files, :updated_at
  end
end
