# frozen_string_literal: true

ActsAsTaggableOn::Tagging.class_eval do
  include PgSearch::Model
  include Folio::ToLabel

  def to_label
    tag.to_label
  end

  pg_search_scope :by_query,
                  associated_against: { tag: %i[name] },
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }
end
