# frozen_string_literal: true

class AddByQueryIndexToFolioPages < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_pages, :atoms_data_for_search, :text

    unless reverting?
      say_with_time "updating models" do
        Folio::Page.find_each do |page|
          page.send(:set_atoms_data_for_search)
          page.update_column(:atoms_data_for_search, page.atoms_data_for_search)
        end
      end
    end

    add_index :folio_pages, %[(setweight(to_tsvector('simple', folio_unaccent(coalesce("folio_pages"."title"::text, ''))), 'A') || setweight(to_tsvector('simple', folio_unaccent(coalesce("folio_pages"."perex"::text, ''))), 'B') || setweight(to_tsvector('simple', folio_unaccent(coalesce("folio_pages"."atoms_data_for_search"::text, ''))), 'C'))], using: :gin, name: "index_folio_pages_on_by_query"
  end
end
