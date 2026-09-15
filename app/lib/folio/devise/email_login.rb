# frozen_string_literal: true

module Folio::Devise::EmailLogin
  class InvalidChallenge < StandardError; end
  class Throttled < StandardError
    attr_reader :retry_after

    def initialize(retry_after: RESEND_INTERVAL.to_i)
      @retry_after = retry_after
      super("Email login delivery limit exceeded")
    end
  end

  class Unavailable < StandardError; end
  class Pending < StandardError; end

  CHALLENGE_LIFETIME = 10.minutes
  TRUST_LIFETIME = 30.days
  RESEND_INTERVAL = 60.seconds
  DELIVERY_WINDOW = 15.minutes
  DELIVERY_LIMIT = 3
  SESSION_KEY = "folio.email_login"
  APPROVAL_SESSION_KEY = "folio.email_login_approval"

  def self.verification_enabled?
    Rails.application.config.folio_users_email_login_verification_enabled
  end

  def self.magic_link_enabled?
    Rails.application.config.folio_users_magic_link_enabled
  end

  def self.enabled?
    verification_enabled? || magic_link_enabled?
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.instrument(event, site_id: nil, purpose: nil, count: 1, kind: "counter")
    ActiveSupport::Notifications.instrument("email_login.folio", event:, site_id:, purpose:, count:, kind:)
  end

  def self.local_path(value, host: nil)
    return unless value.is_a?(String)
    return if value.blank? || value.match?(/[\\\r\n]/)

    uri = URI.parse(value)
    return if uri.host && (uri.host != host || !%w[http https].include?(uri.scheme))
    return if uri.userinfo || (uri.scheme && !uri.host)
    return unless uri.path.start_with?("/") && !uri.path.start_with?("//")

    [uri.path, ("?#{uri.query}" if uri.query), ("##{uri.fragment}" if uri.fragment)].compact.join
  rescue URI::InvalidURIError
    nil
  end
end
