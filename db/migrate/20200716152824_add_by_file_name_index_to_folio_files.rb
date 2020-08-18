# frozen_string_literal: true

class AddByFileNameIndexToFolioFiles < ActiveRecord::Migration[6.0]
  def change
    add_index :folio_files, %[(to_tsvector('simple', folio_unaccent(coalesce("folio_files"."file_name"::text, ''))))], using: :gin, name: "index_folio_files_on_by_file_name"
  end
end
