# frozen_string_literal: true

module Folio::HasNewsletterSubscriptions
  extend ActiveSupport::Concern

  included do
    has_many :newsletter_subscriptions, class_name: "Folio::NewsletterSubscription",
                                        as: :subscribable,
                                        dependent: :destroy

    accepts_nested_attributes_for :newsletter_subscriptions, reject_if: :new_record?

    # after_create :create_newsletter_subscriptions # subscription is created only after_invitation_accepted
    after_update :update_newsletter_subscriptions
  end

  def requires_subscription_confirmation?
    true
  end

  private
    def create_newsletter_subscriptions
      return unless newsletter_subscriptions_enabled?
      return unless auth_site.present?

      existing_subcription = newsletter_subscriptions.by_site(auth_site).first

      if existing_subcription.nil?
        ns = auth_site.newsletter_subscriptions.build(
          email: subscription_email,
          merge_vars: subscription_merge_vars,
          tags: subscription_tags,
          active: should_subscribe_to_newsletter?,
          subscribable: self
        )

        did_create = ns.save

        unless did_create
          message = "NewsletterSubscription for #{self.class.model_name.human} ##{id} - email \"#{subscription_email}\"; site \"#{auth_site.env_aware_domain}\" - failed to create."
          Raven.capture_message(message) if defined?(Raven)
          Sentry.capture_message(message) if defined?(Sentry)
        end
      end

      newsletter_subscriptions
    end

    def update_newsletter_subscriptions
      return unless newsletter_subscriptions_enabled?
      return unless auth_site.present?

      ns = newsletter_subscriptions.by_site(auth_site).first

      if ns.nil?
        if should_subscribe_to_newsletter?
          ns = Folio::NewsletterSubscription.find_or_initialize_by(email: subscription_email, site: auth_site)
          ns.subscribable = self
        else
          return
        end
      end

      did_update = ns.update(email: subscription_email,
                             merge_vars: subscription_merge_vars,
                             tags: subscription_tags,
                             active: should_subscribe_to_newsletter?)

      unless did_update
        message = "NewsletterSubscription for #{self.class.model_name.human} ##{id} - email \"#{subscription_email}\"; site \"#{auth_site.env_aware_domain}\" - failed to update."
        Raven.capture_message(message) if defined?(Raven)
        Sentry.capture_message(message) if defined?(Sentry)
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
