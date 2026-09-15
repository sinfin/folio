# frozen_string_literal: true

module Folio::Devise::EmailLogin::StrategyVerification
  private
    def validate(resource, &block)
      return false unless super

      Folio::Devise::EmailLogin::Gate.check!(resource, request:, purpose: email_login_purpose, remember_me: remember_me?)
      true
    rescue Folio::Devise::EmailLogin::Pending
      fail!(:email_verification_required)
      false
    rescue Folio::Devise::EmailLogin::InvalidChallenge
      fail!(resource.inactive_message)
      false
    rescue Folio::Devise::EmailLogin::Throttled => error
      env["folio.email_login.throttled"] = true
      env["folio.email_login.retry_after"] = error.retry_after
      fail!(:email_login_throttled)
      false
    end
end
