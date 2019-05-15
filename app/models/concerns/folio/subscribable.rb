# frozen_string_literal: true

module Folio::Subscribable
  extend ActiveSupport::Concern

  included do
    after_create :subscribe
  end

  def subscribe
    if !Rails.env.test? || (Rails.env.development? && ENV['DEV_MAILCHIMP'])
      Folio::Mailchimp::SubscribeJob.perform_later(self, additional_subscription_data)
    end
  end

  def additional_subscription_data
    {}
  end
end
