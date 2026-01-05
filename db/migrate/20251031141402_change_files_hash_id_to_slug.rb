# frozen_string_literal: true

class ChangeFilesHashIdToSlug < ActiveRecord::Migration[8.0]
  def change
    rename_column :folio_files, :hash_id, :slug
  end
end
