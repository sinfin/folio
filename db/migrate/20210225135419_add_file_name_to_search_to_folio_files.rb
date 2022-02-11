# frozen_string_literal: true

class AddFileNameToSearchToFolioFiles < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_files, :file_name_for_search, :string
    add_index :folio_files, %[(to_tsvector('simple', folio_unaccent(coalesce("folio_files"."file_name_for_search"::text, ''))))], using: :gin, name: "index_folio_files_on_by_file_name_for_search"

    unless reverting?
      if ActiveRecord::Migration.connection.index_exists? :folio_files, name: :by_file_name
        remove_index :folio_files, name: :index_folio_files_on_by_file_name
      end

      sql = "UPDATE folio_files SET file_name_for_search = REPLACE(REPLACE(file_name, '-', '{d}'), '_', '{u}') WHERE file_name IS NOT NULL"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
