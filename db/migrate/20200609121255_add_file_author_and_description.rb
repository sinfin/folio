# frozen_string_literal: true

class AddFileAuthorAndDescription < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_files, :author, :string
    add_column :folio_files, :description, :text
  end
end
