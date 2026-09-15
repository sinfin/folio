# frozen_string_literal: true

class Folio::Devise::EmailLogin::RequestSession
  attr_reader :request

  def initialize(request)
    @request = ActionDispatch::Request.new(request.env)
  end

  def site
    @site ||= Folio::Current.get_site(host: request.host)
  end

  def data
    request.session[Folio::Devise::EmailLogin::SESSION_KEY] || {}
  end

  def challenge
    return unless data["id"] && data["browser_nonce"]

    record = Folio::Users::EmailLoginChallenge.find_by(id: data["id"], site:)
    record if record&.browser_matches?(data["browser_nonce"])
  end

  def state
    if record = challenge
      return "revoked" if %w[waiting approved].include?(record.state) && !record.usable_for?(site)

      record.state
    elsif data["anonymous"]
      data["expires_at"].to_f > Time.current.to_f ? "waiting" : "expired"
    else
      "revoked"
    end
  end

  def begin!(user:, purpose:, email: user&.email, remember_me: false, trust_browser: true, return_path: nil)
    Folio::Devise::EmailLogin::DeliveryLimit.consume!(site:, email:)
    previous = challenge
    nonce = data["browser_nonce"].presence || SecureRandom.hex(32)
    return_path ||= Folio::Devise::EmailLogin.local_path(request.session["user_return_to"], host: request.host)

    if user
      previous = nil unless previous&.user_id == user.id && previous&.consumed_at.nil?
      record, token = Folio::Devise::EmailLogin::IssueChallenge.call(user:, site:, nonce:, purpose:, previous:,
                                                                   return_path:, remember_me:, trust_browser:)
      request.session[Folio::Devise::EmailLogin::SESSION_KEY] = {
        "id" => record.id, "browser_nonce" => nonce, "email" => email,
        "expires_at" => record.expires_at.to_f, "trust_browser" => trust_browser,
      }
      Folio::Users::EmailLoginDeliveryJob.deliver_later(record, token, locale: I18n.locale.to_s)
    else
      begin_anonymous!(email)
    end
  end

  def resend!
    raise Folio::Devise::EmailLogin::InvalidChallenge unless %w[waiting approved].include?(state)

    if record = challenge
      raise Folio::Devise::EmailLogin::InvalidChallenge unless record.usable_for?(site)

      begin!(user: record.user, purpose: record.purpose, remember_me: record.remember_me,
             trust_browser:, return_path: record.return_path)
    elsif data["anonymous"]
      begin!(user: nil, purpose: "magic_link", email: data["email"])
    else
      raise Folio::Devise::EmailLogin::InvalidChallenge
    end
  end

  def resend_at
    sent_at = challenge&.created_at || Time.at(data["created_at"].to_f)
    [sent_at + Folio::Devise::EmailLogin::RESEND_INTERVAL, Time.at(data["retry_at"].to_f)].max
  end

  def postpone_resend_until(time)
    request.session[Folio::Devise::EmailLogin::SESSION_KEY] = data.merge("retry_at" => time.to_f)
  end

  def trust_browser
    data.fetch("trust_browser", true)
  end

  def trust_browser=(value)
    return if data.empty?

    request.session[Folio::Devise::EmailLogin::SESSION_KEY] = data.merge("trust_browser" => value)
  end

  def cancel!
    if record = challenge
      record.user.with_lock do
        record.with_lock { record.update!(revoked_at: Time.current) unless record.consumed_at? }
      end
    end
    request.session.delete(Folio::Devise::EmailLogin::SESSION_KEY)
  end

  private
    def begin_anonymous!(email)
      request.session[Folio::Devise::EmailLogin::SESSION_KEY] = {
        "anonymous" => true, "email" => email,
        "expires_at" => Folio::Devise::EmailLogin::CHALLENGE_LIFETIME.from_now.to_f,
        "created_at" => Time.current.to_f,
        "trust_browser" => trust_browser,
      }
    end
end
