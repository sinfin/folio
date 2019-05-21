# frozen_string_literal: true

module Folio::Subscribable
  extend ActiveSupport::Concern

  included do
    after_create :subscribe
  end

  def subscribe
    if !Rails.env.test? && (!Rails.env.development? || ENV['DEV_MAILCHIMP'])
      Folio::Mailchimp::SubscribeJob.perform_now(self, status: subscription_default_status,
                                                       merge_vars: subscription_merge_vars)
    end
  end

  private

    def subscription_default_status
      nil
    end

    def subscription_merge_vars
      {}
    end
end
