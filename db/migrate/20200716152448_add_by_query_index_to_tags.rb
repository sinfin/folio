# frozen_string_literal: true

class AddByQueryIndexToTags < ActiveRecord::Migration[6.0]
  def change
    add_index :tags, %[(to_tsvector('simple', folio_unaccent(coalesce("tags"."name"::text, ''))))], using: :gin, name: 'index_tags_on_by_query'
  end
end
