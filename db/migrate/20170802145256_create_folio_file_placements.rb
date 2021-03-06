# frozen_string_literal: true

class CreateFolioFilePlacements < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_file_placements do |t|
      t.belongs_to :placement, polymorphic: true
      t.belongs_to :file

      t.string :caption
      t.integer :position

      t.timestamps
    end
  end
end
