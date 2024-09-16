# frozen_string_literal: true

Emailbutler::Message.class_eval do
  include Folio::BelongsToSite
  include Folio::Filterable
  include PgSearch::Model

  pg_search_scope :by_query,
                  against: %i[send_to subject],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }
end
