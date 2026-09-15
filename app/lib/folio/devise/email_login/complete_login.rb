# frozen_string_literal: true

class Folio::Devise::EmailLogin::CompleteLogin
  def self.call(controller, trust_browser: nil)
    pending = Folio::Devise::EmailLogin::RequestSession.new(controller.request)
    challenge = pending.challenge
    raise Folio::Devise::EmailLogin::InvalidChallenge unless challenge

    existing = controller.warden.user(:user)
    if existing && existing.id != challenge.user_id
      pending.cancel!
      raise Folio::Devise::EmailLogin::InvalidChallenge
    end

    if challenge.consumed_at?
      raise Folio::Devise::EmailLogin::InvalidChallenge unless existing&.id == challenge.user_id

      return controller.session["folio.email_login_completed_path"]
    end

    user = challenge.consume!(nonce: pending.data["browser_nonce"], site: pending.site)
    controller.request.env["folio.email_login.completed_user_id"] = user.id
    controller.store_location_for(:user, challenge.return_path) if challenge.return_path.present?
    user.remember_me = challenge.remember_me
    user.after_database_authentication if challenge.purpose == "password"
    controller.sign_in(:user, user)

    # Host after_sign_in hooks may leave unsaved profile-validation changes.
    trust_user = user.class.find(user.id)
    trust_user.with_lock do
      trust_user.authentication_site = pending.site
      browser = Folio::Devise::EmailLogin::BrowserTrust.new(request: pending.request, user: trust_user, site: pending.site)
      trust_requested = trust_browser.nil? ? challenge.trust_browser : trust_browser
      if trust_requested && trust_user.email_authentication_version == challenge.authentication_version && trust_user.active_for_authentication?
        browser.verify!
      else
        browser.revoke!
      end
    end

    path = Folio::Devise::EmailLogin.local_path(controller.after_sign_in_path_for(user), host: pending.request.host)
    path ||= controller.main_app.root_path
    controller.session["folio.email_login_completed_path"] = path
    Folio::Devise::EmailLogin.instrument("completed", site_id: pending.site.id, purpose: challenge.purpose)
    path
  end
end
