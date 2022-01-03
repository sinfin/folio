# frozen_string_literal: true

module Folio::HasNewsletterSubscription
  extend ActiveSupport::Concern

  included do
    has_one :newsletter_subscription, class_name: "Folio::NewsletterSubscription",
                                      as: :subscribable,
                                      dependent: :destroy

    after_save :update_newsletter_subscription
  end

  def requires_subscription_confirmation?
    true
  end

  def update_newsletter_subscription
    if newsletter_subscription.present? || should_subscribe_to_newsletter?
      build_newsletter_subscription if newsletter_subscription.nil?

      did_update = newsletter_subscription.update(email: subscription_email,
                                                  merge_vars: subscription_merge_vars,
                                                  tags: subscription_tags,
                                                  active: should_subscribe_to_newsletter?)
      unless did_update
        Raven.capture_message("NewsletterSubscription for #{self.class.model_name.human} ##{id} - email \"#{subscription_email}\" - failed to update.") if defined?(Raven)
      end
    end
  end

  private
    def subscription_email
      email
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
