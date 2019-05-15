# frozen_string_literal: true

module Folio::Subscribable
  extend ActiveSupport::Concern

  included do
    after_create :subscribe
  end

  def subscribe
    if !Rails.env.test? && (!Rails.env.development? || ENV['DEV_MAILCHIMP'])
      Folio::Mailchimp::SubscribeJob.perform_later(self, subscription_merge_vars)
    end
  end

  private

    def subscription_merge_vars
      {}
    end
end
