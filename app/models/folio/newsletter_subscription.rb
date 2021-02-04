# frozen_string_literal: true

class Folio::NewsletterSubscription < Folio::ApplicationRecord
  include Folio::Subscribable

  # Validations
  validates_format_of :email, with: Folio::EMAIL_REGEXP

  # Scopes
  default_scope { order(created_at: :desc) }

  pg_search_scope :by_query,
                  against: %i[email],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  after_create :subscribe

  def title
    email
  end

  def self.csv_attribute_names
    %i[id email created_at]
  end

  def csv_attributes
    self.class.csv_attribute_names.map do |attr|
      send(attr)
    end
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
#
