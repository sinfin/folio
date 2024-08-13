# frozen_string_literal: true

class CreateFolioAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :folio_attribute_types do |t|
      t.belongs_to :site

      t.string :title
      t.string :type, index: true
      t.integer :position, index: true

      t.string :data_type, default: "string"

      t.integer :folio_attributes_count, index: true

      t.timestamps
    end

    create_table :folio_attributes do |t|
      t.belongs_to :folio_attribute_type
      t.belongs_to :placement, polymorphic: true

      t.string :value

      t.timestamps
    end
  end
end
