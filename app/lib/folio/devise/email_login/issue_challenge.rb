# frozen_string_literal: true

class Folio::Devise::EmailLogin::IssueChallenge
  def self.call(**args)
    new(**args).call
  end

  def initialize(user:, site:, nonce:, purpose:, previous: nil, return_path: nil, remember_me: false, trust_browser: true)
    @user = user
    @site = site
    @nonce = nonce
    @purpose = purpose
    @previous = previous
    @return_path = return_path
    @remember_me = remember_me
    @trust_browser = trust_browser
  end

  def call
    challenge = nil
    token = SecureRandom.hex(32)

    @user.with_lock do
      @user.authentication_site = @site
      unless (@user.auth_site_id == @site.id || @user.superadmin?) && @user.active_for_authentication?
        raise Folio::Devise::EmailLogin::InvalidChallenge
      end

      if @previous
        @previous.with_lock do
          unless @previous.user_id == @user.id && @previous.site_id == @site.id && @previous.browser_matches?(@nonce) && @previous.consumed_at.nil?
            raise Folio::Devise::EmailLogin::InvalidChallenge
          end
          @previous.update!(revoked_at: Time.current)
        end
      end

      challenge = @user.email_login_challenges.create!(site: @site,
                                                       purpose: @purpose,
                                                       token_digest: Folio::Devise::EmailLogin.digest(token),
                                                       browser_nonce_digest: Folio::Devise::EmailLogin.digest(@nonce),
                                                       expires_at: Folio::Devise::EmailLogin::CHALLENGE_LIFETIME.from_now,
                                                       authentication_version: @user.email_authentication_version,
                                                       return_path: Folio::Devise::EmailLogin.local_path(@return_path),
                                                       remember_me: @remember_me,
                                                       trust_browser: @trust_browser)
    end

    Folio::Devise::EmailLogin.instrument("created", site_id: @site.id, purpose: @purpose)
    [challenge, token]
  end
end
