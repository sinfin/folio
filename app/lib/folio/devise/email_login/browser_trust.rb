# frozen_string_literal: true

class Folio::Devise::EmailLogin::BrowserTrust
  def initialize(request:, user:, site:)
    @request = request
    @user = user
    @site = site
  end

  def trusted?
    record&.trusted_for?(user: @user, site: @site) || false
  end

  def record_authentication!
    @user.with_lock do
      if trusted?
        record.update!(last_authenticated_at: Time.current)
        write_cookie(@request.cookie_jar[cookie_name])
      end
    end
  end

  def verify!
    revoke!
    token = SecureRandom.hex(32)
    @record = @user.trusted_browsers.create!(site: @site,
                                           token_digest: Folio::Devise::EmailLogin.digest(token),
                                           authentication_version: @user.email_authentication_version,
                                           verified_at: Time.current,
                                           last_authenticated_at: Time.current)
    write_cookie(token)
  end

  def revoke!
    record.update!(revoked_at: Time.current) if record
    @request.cookie_jar.delete(cookie_name, path: "/")
    @record = nil
  end

  private
    def record
      return @record if defined?(@record)

      token = @request.cookie_jar[cookie_name]
      @record = if token.present?
        @user.trusted_browsers.find_by(site: @site, token_digest: Folio::Devise::EmailLogin.digest(token))
      end
    end

    def cookie_name
      "folio_trusted_browser_#{@site.id}_#{@user.id}"
    end

    def write_cookie(token)
      @request.cookie_jar[cookie_name] = { value: token, expires: record.expires_at,
                                        secure: @request.ssl?, httponly: true, same_site: :lax, path: "/" }
    end
end
