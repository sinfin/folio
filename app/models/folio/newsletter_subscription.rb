# frozen_string_literal: true

class Folio::NewsletterSubscription < Folio::ApplicationRecord
  include Folio::BelongsToSite

  has_sanitized_fields :email

  belongs_to :subscribable, polymorphic: true,
                            optional: true

  validates :email,
            format: { with: Folio::EMAIL_REGEXP }

  validates :email,
            uniqueness: { scope: :site_id }

  validate :validate_belongs_to_subscribable_site

  default_scope { order(id: :desc) }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_active, -> (bool) {
    case bool
    when true, "true"
      active
    when false, "false"
      inactive
    else
      all
    end
  }

  pg_search_scope :by_query,
                  against: %i[email],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  serialize :tags, Array
  serialize :merge_vars, Hash

  after_commit do
    if saved_changes? || destroyed?
      if email_before_last_save
        # email changed > delete old subscription
        update_mailchimp_subscription(email_before_last_save)
      end

      update_mailchimp_subscription
    end
  end

  def requires_subscription_confirmation?
    return true unless subscribable.respond_to?(:requires_subscription_confirmation?)

    subscribable.requires_subscription_confirmation?
  end

  def self.csv_attribute_names
    %i[id email active created_at]
  end

  def csv_attributes(controller = nil)
    self.class.csv_attribute_names.map do |attr|
      send(attr)
    end
  end

  def self.subscribable_sites
    Folio::Site.all
  end

  def self.clears_page_cache_on_save?
    false
  end

  private
    def update_mailchimp_subscription(email_for_subscription = nil)
      return unless Rails.application.config.folio_newsletter_subscription_service == :mailchimp
      return unless Rails.env.production? || ENV["DEV_MAILCHIMP"]

      # TODO: multiple mailchimp lists not implemented yet
      return unless Rails.application.config.folio_site_is_a_singleton

      Folio::Mailchimp::CreateOrUpdateSubscriptionJob.perform_later(email_for_subscription || email)
    end

    def validate_belongs_to_subscribable_site
      return if Rails.application.config.folio_site_is_a_singleton

      errors.add(:site, :invalid) unless site.in?(self.class.subscribable_sites)
    end
end

# == Schema Information
#
# Table name: folio_newsletter_subscriptions
#
#  id                :bigint(8)        not null, primary key
#  email             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  subscribable_type :string
#  subscribable_id   :bigint(8)
#  active            :boolean          default(TRUE)
#  tags              :string
#  merge_vars        :text
#  site_id           :bigint(8)
#
# Indexes
#
#  index_folio_newsletter_subscriptions_on_site_id       (site_id)
#  index_folio_newsletter_subscriptions_on_subscribable  (subscribable_type,subscribable_id)
#
