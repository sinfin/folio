# frozen_string_literal: true

Rails.application.config.to_prepare do
  if Folio::Devise::EmailLogin.enabled? && Rails.application.config.folio_crossdomain_devise
    raise ArgumentError, "Folio email login verification does not support crossdomain Devise"
  end

  Warden::Strategies.add(:database_authenticatable, Folio::Devise::EmailLogin::DatabaseAuthenticatable)
  Warden::Strategies.add(:rememberable, Folio::Devise::EmailLogin::Rememberable)
end

Warden::Manager.after_set_user except: :fetch do |user, warden, _options|
  if Folio::Devise::EmailLogin.enabled? && user.is_a?(Folio::User)
    pending = Folio::Devise::EmailLogin::RequestSession.new(warden.request)
    Folio::Devise::EmailLogin::BrowserTrust.new(request: pending.request, user:, site: pending.site).record_authentication!
  end
end

Rails.application.config.filter_parameters += %i[email_login_token browser_nonce]
