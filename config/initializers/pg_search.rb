# frozen_string_literal: true

PgSearch.unaccent_function = "folio_unaccent"

module Folio::PgSearchTsearchSanitizer
  # pg_search wraps every term in single quotes before handing it to
  # `to_tsquery`, and `folio_unaccent` runs on the term inside those quotes.
  # A handful of characters unaccent into an apostrophe or a backslash (ŉ → 'n,
  # ‛ → '), which closes the quote early:
  #
  #   to_tsquery('simple', ''' ' || folio_unaccent('ŉ') || ' ''' || ':*')
  #   => ERROR:  syntax error in tsquery: "' 'n ':*"
  #
  # pg_search strips ' ? \ : ‘ ’ on its own (DISALLOWED_TSQUERY_CHARACTERS) but
  # cannot know what unaccent will produce, so fold the rest here. Everything
  # else must pass through untouched — `parameterize` used to be used instead
  # and it also split on dots and at-signs, which broke every email search:
  # Postgres keeps "petr.tobiska@volny.cz" as a single `email` lexeme, so the
  # address only matches when it reaches to_tsquery as a single term.
  #
  # Regenerate the list with:
  #   SELECT chr(i) FROM generate_series(1, 65533) i
  #   WHERE i NOT BETWEEN 55296 AND 57343
  #     AND folio_unaccent(chr(i)) ~ '[''\\]';
  UNSAFE_AFTER_UNACCENT = /[ŉʹʻʼʽˈ‛′＇∖﹨＼]/

  private
    def query
      super.to_s.gsub(UNSAFE_AFTER_UNACCENT) do |char|
        ActiveSupport::Inflector.transliterate(char, locale: :en).delete("'\\")
      end
    end
end

PgSearch::Features::TSearch.prepend(Folio::PgSearchTsearchSanitizer)

PgSearch.multisearch_options = {
  using: { tsearch: { prefix: true } },
  ignoring: :accents,
}
