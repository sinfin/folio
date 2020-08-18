# frozen_string_literal: true

class AddByAuthorIndexToFolioFiles < ActiveRecord::Migration[6.0]
  def change
    add_index :folio_files, %[(to_tsvector('simple', folio_unaccent(coalesce("folio_files"."author"::text, ''))))], using: :gin, name: "index_folio_files_on_by_author"
  end
end
