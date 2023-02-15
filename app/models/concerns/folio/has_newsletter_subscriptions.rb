# frozen_string_literal: true

module Folio::HasNewsletterSubscriptions
  extend ActiveSupport::Concern

  included do
    has_many :newsletter_subscriptions, class_name: "Folio::NewsletterSubscription",
                                        as: :subscribable,
                                        dependent: :destroy

    accepts_nested_attributes_for :newsletter_subscriptions, reject_if: :new_record?

    after_create :create_newsletter_subscriptions
    after_update :update_newsletter_subscriptions
  end

  def requires_subscription_confirmation?
    true
  end

  private
    def create_newsletter_subscriptions
      if Rails.application.config.folio_site_is_a_singleton
        update_newsletter_subscriptions
      else
        return unless newsletter_subscriptions_enabled?

        site_ids = newsletter_subscriptions.map(&:site_id)
        to_create = Folio::NewsletterSubscription.subscribable_sites.reject { |site| site.id.in?(site_ids) }
        to_create.each do |site|
          ns = site.newsletter_subscriptions.find_by_email(subscription_email) || site.newsletter_subscriptions.build(email: subscription_email)

          if respond_to?(:source_site) && source_site.present? && site != site
            active = false
          else
            active = should_subscribe_to_newsletter?
          end

          did_create = ns.update(email: subscription_email,
                                 merge_vars: subscription_merge_vars,
                                 tags: subscription_tags,
                                 active:,
                                 subscribable: self)
          unless did_create
            Raven.capture_message("NewsletterSubscription for #{self.class.model_name.human} ##{id} - email \"#{subscription_email}\", site \"#{site.domain}\" - failed to create.") if defined?(Raven)
          end
        end
      end

      newsletter_subscriptions
    end

    def update_newsletter_subscriptions
      return unless newsletter_subscriptions_enabled?

      # manual update is required for multiple newsletter subscriptions
      return unless Rails.application.config.folio_site_is_a_singleton

      ns = newsletter_subscriptions.first

      if ns.nil? && should_subscribe_to_newsletter?
        ns = Folio::NewsletterSubscription.find_or_initialize_by(email: subscription_email)
        ns.subscribable = self
      else
        # no need for NS record - user isn't subscribed
        return
      end

      did_update = ns.update(email: subscription_email,
                             merge_vars: subscription_merge_vars,
                             tags: subscription_tags,
                             active: should_subscribe_to_newsletter?)

      unless did_update
        Raven.capture_message("NewsletterSubscription for #{self.class.model_name.human} ##{id} - email \"#{subscription_email}\" - failed to update.") if defined?(Raven)
      end
    end

    def subscription_email
      email
    end

    def newsletter_subscriptions_enabled?
      true
    end

    def should_subscribe_to_newsletter?
      true
    end

    def subscription_merge_vars
      {}
    end

    def subscription_tags
      []
    end
end
