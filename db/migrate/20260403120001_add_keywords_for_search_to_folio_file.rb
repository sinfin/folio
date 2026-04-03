class AddKeywordsForSearchToFolioFile < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_folio_files_on_keywords_for_search"

  def up
    add_column :folio_files, :keywords_for_search, :text

    execute <<~SQL
      UPDATE folio_files
      SET keywords_for_search = CASE
        WHEN json_typeof((file_metadata->'keywords')::json) = 'array'
          THEN (SELECT string_agg(value, ' ') FROM json_array_elements_text((file_metadata->'keywords')::json))
        WHEN json_typeof((file_metadata->'keywords')::json) = 'string'
          THEN file_metadata->>'keywords'
      END
      WHERE file_metadata IS NOT NULL
        AND file_metadata->>'keywords' IS NOT NULL
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
        ON folio_files
        USING gin (
          to_tsvector('simple', folio_unaccent(COALESCE(keywords_for_search, '')))
        )
    SQL
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
    remove_column :folio_files, :keywords_for_search
  end
end