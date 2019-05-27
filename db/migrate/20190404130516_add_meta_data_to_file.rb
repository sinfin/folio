# frozen_string_literal: true

class AddMetaDataToFile < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_files, :file_metadata, :json, index: true
  end
end
