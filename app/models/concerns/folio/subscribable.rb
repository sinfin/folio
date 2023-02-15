# frozen_string_literal: true

module Folio::Subscribable
  extend ActiveSupport::Concern

  included do
    ActiveSupport::Deprecation.warn("Folio::Subscribable is deprecated, use Folio::HasNewsletterSubscriptions instead!")
  end

  def subscribe
    return if email.nil?

    if Rails.env.production? || ENV["DEV_MAILCHIMP"]
      status = model.class.requires_subscription_confirmation? ? "pending" : "subscribed"

      Folio::Mailchimp::SubscribeJob.perform_later(email, merge_vars: subscription_merge_vars,
                                                          tags: subscription_tags,
                                                          status:)
    end
  end

  def unsubscribe
    return if email.nil?

    if Rails.env.production? || ENV["DEV_MAILCHIMP"]
      Folio::Mailchimp::UnsubscribeJob.perform_later(email)
    end
  end

  module ClassMethods
    def requires_subscription_confirmation?
      true
    end
  end

  private
    def subscription_merge_vars
      {}
    end

    def subscription_tags
      []
    end
end
