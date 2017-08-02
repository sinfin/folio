class AddMagicAttrstoFile < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_files, :file_width, :integer
    add_column :folio_files, :file_height, :integer
    add_column :folio_files, :file_size, :bigint
    add_column :folio_files, :mime_type, :string, limit: 255
  end
end
