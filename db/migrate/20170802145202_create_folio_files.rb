class CreateFolioFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_files do |t|
      t.string :file_uid
      t.string :file_name
      t.string :type, index: true

      t.text :thumbnail_sizes, default: "--- {}\n"

      t.timestamps
    end
  end
end
