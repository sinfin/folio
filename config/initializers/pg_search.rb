# frozen_string_literal: true

PgSearch.unaccent_function = "folio_unaccent"

module Folio::PgSearchTsearchSanitizer
  private
    def query
      super.to_s.parameterize(separator: " ")
    end
end

PgSearch::Features::TSearch.prepend(Folio::PgSearchTsearchSanitizer)

PgSearch.multisearch_options = {
  using: { tsearch: { prefix: true } },
  ignoring: :accents,
}
