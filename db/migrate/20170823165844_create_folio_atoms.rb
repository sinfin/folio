# frozen_string_literal: true

class CreateFolioAtoms < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_atoms do |t|
      t.string :type
      t.belongs_to :node
      t.text :content
      t.integer :position

      t.timestamps
    end
  end
end
