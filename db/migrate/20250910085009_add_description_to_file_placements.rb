# frozen_string_literal: true

class AddDescriptionToFilePlacements < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_file_placements, :description, :text
  end
end
