# frozen_string_literal: true

class Folio::Page::Cookies < Folio::Page
  include Folio::Singleton
end

# == Schema Information
#
# Table name: folio_pages
#
#  id                    :bigint(8)        not null, primary key
#  title                 :string
#  slug                  :string
#  perex                 :text
#  meta_title            :string(512)
#  meta_description      :text
#  ancestry              :string
#  type                  :string
#  featured              :boolean
#  position              :integer
#  published             :boolean
#  published_at          :datetime
#  original_id           :integer
#  locale                :string(6)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  ancestry_slug         :string
#  site_id               :bigint(8)
#  atoms_data_for_search :text
#
# Indexes
#
#  index_folio_pages_on_ancestry      (ancestry)
#  index_folio_pages_on_by_query      ((((setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((title)::text, ''::text))), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(perex, ''::text))), 'B'::"char")) || setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(atoms_data_for_search, ''::text))), 'C'::"char")))) USING gin
#  index_folio_pages_on_featured      (featured)
#  index_folio_pages_on_locale        (locale)
#  index_folio_pages_on_original_id   (original_id)
#  index_folio_pages_on_position      (position)
#  index_folio_pages_on_published     (published)
#  index_folio_pages_on_published_at  (published_at)
#  index_folio_pages_on_site_id       (site_id)
#  index_folio_pages_on_slug          (slug)
#  index_folio_pages_on_type          (type)
#
