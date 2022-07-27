# frozen_string_literal: true

class RmFilesMimeTypeColumn < ActiveRecord::Migration[6.1]
  def change
    remove_column :folio_files, :mime_type, :string
  end
end
