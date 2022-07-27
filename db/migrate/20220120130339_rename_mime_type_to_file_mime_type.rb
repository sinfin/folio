# frozen_string_literal: true

class RenameMimeTypeToFileMimeType < ActiveRecord::Migration[6.1]
  def change
    add_column :folio_files, :file_mime_type, :string

    unless reverting?
      execute "UPDATE folio_files SET file_mime_type = mime_type;"
    end
  end
end
