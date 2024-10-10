# frozen_string_literal: true

class AddFileFields < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_files, :attribution_source, :string
    add_column :folio_files, :attribution_source_url, :string
    add_column :folio_files, :attribution_copyright, :string
    add_column :folio_files, :attribution_licence, :string
  end
end
