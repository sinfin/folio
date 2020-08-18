# frozen_string_literal: true

class AddSearchIndexToPgSearchDocuments < ActiveRecord::Migration[5.2]
  def change
    add_index :pg_search_documents, %[(to_tsvector('simple', folio_unaccent(coalesce("pg_search_documents"."content"::text, ''))))], using: :gin, name: "index_pg_search_documents_on_public_search"
  end
end
