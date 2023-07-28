# frozen_string_literal: true

ActsAsTaggableOn::Tag.class_eval do
  include PgSearch::Model
  include Folio::ToLabel

  pg_search_scope :by_query,
                  against: %i[name],
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  scope :ordered, -> { order(name: :asc) }
end
