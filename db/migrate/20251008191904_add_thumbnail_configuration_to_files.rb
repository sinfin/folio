# frozen_string_literal: true

class AddThumbnailConfigurationToFiles < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_files, :thumbnail_configuration, :jsonb
  end
end
