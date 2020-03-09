# frozen_string_literal: true

class CreateFolioContentTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :folio_content_templates do |t|
      t.text :content
      t.integer :position, index: true

      t.string :type, index: true

      t.timestamps
    end
  end
end
