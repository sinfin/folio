class CreateFolioImages < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_images do |t|
      t.string :photo_uid
      t.string :photo_name
      t.text :thumbnail_sizes, default: "--- {}\n"

      t.timestamps
    end
  end
end
