# frozen_string_literal: true

class Folio::Devise::EmailLogin::Gate
  def self.check!(user, request:, purpose:, remember_me: false)
    return unless Folio::Devise::EmailLogin.verification_enabled? && user.is_a?(Folio::User)

    pending = Folio::Devise::EmailLogin::RequestSession.new(request)
    user.authentication_site = pending.site
    unless (user.auth_site_id == pending.site.id || user.superadmin?) && user.active_for_authentication?
      raise Folio::Devise::EmailLogin::InvalidChallenge
    end

    return if request.env["folio.email_login.completed_user_id"] == user.id
    return if request.env["folio.email_login.verified_by_token_user_id"] == user.id
    return if Folio::Devise::EmailLogin::BrowserTrust.new(request: pending.request, user:, site: pending.site).trusted?

    return_path = if purpose == "rememberable" && request.get? && request.format.html? && !request.xhr?
      Folio::Devise::EmailLogin.local_path(request.fullpath)
    end
    pending.begin!(user:, purpose:, remember_me:, return_path:)
    request.env["folio.email_login.pending"] = true
    request.env["folio.email_login.purpose"] = purpose
    raise Folio::Devise::EmailLogin::Pending
  end
end
