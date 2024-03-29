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
      return unless newsletter_subscriptions_enabled?

      subscribable_sites = Folio::NewsletterSubscription.subscribable_sites

      if respond_to?(:source_site) && source_site.present? && source_site.in?(subscribable_sites)
        subscribable_source_site = source_site
      end

      present_site_ids = newsletter_subscriptions.map(&:site_id)
      to_create = subscribable_sites.reject { |site| site.id.in?(present_site_ids) }
      to_create.each do |site|
        ns = site.newsletter_subscriptions.find_by_email(subscription_email) || site.newsletter_subscriptions.build(email: subscription_email)

        if subscribable_source_site.present?
          active = subscribable_source_site == site
        else
          active = should_subscribe_to_newsletter?
        end

        did_create = ns.update(email: subscription_email,
                                merge_vars: subscription_merge_vars,
                                tags: subscription_tags,
                                active:,
                                subscribable: self)

        unless did_create
          Raven.capture_message("NewsletterSubscription for #{self.class.model_name.human} ##{id} - email \"#{subscription_email}\", site \"#{site.env_aware_domain}\" - failed to create.") if defined?(Raven)
        end
      end

      newsletter_subscriptions
    end

    def update_newsletter_subscriptions
      return unless newsletter_subscriptions_enabled?

      Folio::NewsletterSubscription.subscribable_sites.each do |site|
        ns = newsletter_subscriptions.by_site(site).first

        if ns.nil? && should_subscribe_to_newsletter?
          ns = Folio::NewsletterSubscription.find_or_initialize_by(email: subscription_email, site:)
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
          Raven.capture_message("NewsletterSubscription for #{self.class.model_name.human} ##{id} - email \"#{subscription_email}\"; site `#{site.env_aware_domain}`- failed to update.") if defined?(Raven)
        end
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
