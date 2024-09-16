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

  def self.model_name
    @_model_name ||= super.tap do |name|
      name.param_key = "email_message"
      name.route_key = "email_messages"
    end
  end
end
