# frozen_string_literal: true

module Folio::Subscribable
  extend ActiveSupport::Concern

  def subscribe
    if Rails.env.production? || ENV["DEV_MAILCHIMP"]
      Folio::Mailchimp::SubscribeJob.perform_later(self, merge_vars: subscription_merge_vars,
                                                         tags: subscription_tags)
    end
  end

  def unsubscribe
    if Rails.env.production? || ENV["DEV_MAILCHIMP"]
      Folio::Mailchimp::UnsubscribeJob.perform_later(self)
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
