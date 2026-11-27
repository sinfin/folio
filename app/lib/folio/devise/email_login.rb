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
  CODE_LENGTH = 6
  CODE_FORMAT = /\A\d{#{CODE_LENGTH}}\z/
  CODE_ATTEMPTS = 5
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

  # The emailed code is derived from the link token, so delivery needs no extra secret.
  def self.code(token)
    number = OpenSSL::HMAC.hexdigest("SHA256", code_key, "code:#{token}").to_i(16) % (10**CODE_LENGTH)
    number.to_s.rjust(CODE_LENGTH, "0")
  end

  # Keyed so that a database dump alone cannot brute-force the short code.
  def self.code_digest(code, token_digest:)
    OpenSSL::HMAC.hexdigest("SHA256", code_key, "digest:#{token_digest}:#{code}")
  end

  # Accepts pasted codes with spaces or dashes, e.g. "123 456" or "123-456".
  def self.normalize_code(value)
    return unless value.is_a?(String) && value.bytesize <= 64 && value.valid_encoding?

    code = value.gsub(/[[:space:]\-\u2010-\u2015]/, "")
    code if code.match?(CODE_FORMAT)
  end

  def self.code_key
    Rails.application.key_generator.generate_key("folio.email_login.code", 32)
  end
  private_class_method :code_key

  def self.instrument(event, site_id: nil, purpose: nil, count: 1, kind: "counter", via: nil)
    payload = { event:, site_id:, purpose:, count:, kind: }
    payload[:via] = via if via
    ActiveSupport::Notifications.instrument("email_login.folio", payload)
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
