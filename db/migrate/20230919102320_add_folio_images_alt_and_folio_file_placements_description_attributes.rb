# frozen_string_literal: true

class AddFolioImagesAltAndFolioFilePlacementsDescriptionAttributes < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :alt, :string
    add_column :folio_file_placements, :description, :text
  end
end
