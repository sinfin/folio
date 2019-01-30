# frozen_string_literal: true

class Folio::NewsletterSubscription < Folio::ApplicationRecord
  belongs_to :visit, optional: true

  # Validations
  validates_format_of :email, with: Folio::EMAIL_REGEXP

  # Scopes
  default_scope { order(created_at: :desc) }

  pg_search_scope :by_query,
                  against: %i[email],
                  ignoring: :accents

  def title
    email
  end

  def self.clears_page_cache_on_save?
    false
  end
end

# == Schema Information
#
# Table name: folio_newsletter_subscriptions
#
#  id         :bigint(8)        not null, primary key
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  visit_id   :bigint(8)
#
# Indexes
#
#  index_folio_newsletter_subscriptions_on_visit_id  (visit_id)
#
