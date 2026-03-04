# frozen_string_literal: true

class AddFulltextIndexToFolioFiles < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_folio_files_on_by_label_query"

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
        ON folio_files
        USING gin (
          (
            to_tsvector('simple', folio_unaccent(COALESCE(file_name_for_search::text, ''))) ||
            to_tsvector('simple', folio_unaccent(COALESCE(headline::text, ''))) ||
            to_tsvector('simple', folio_unaccent(COALESCE(description::text, '')))
          )
        )
    SQL
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
  end
end
