# frozen_string_literal: true

PgSearch.unaccent_function = 'folio_unaccent'

PgSearch.multisearch_options = {
  using: { tsearch: { prefix: true } },
  ignoring: :accents,
}
