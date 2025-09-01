# frozen_string_literal: true

class AddEmbedSupportToFilePlacements < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_file_placements, :folio_embed_data, :jsonb
  end
end
