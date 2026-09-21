# frozen_string_literal: true

require "omniauth"
require Folio::Engine.root.join("app/models/folio/omniauth") # to load Folio::Omniauth namespace

OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)

Folio::Omniauth.setup_providers(Rails.application.config.folio_users_omniauth_providers)

Rails.application.config.action_dispatch.cookies_same_site_protection = lambda { |request|
  request.path == "/users/auth/apple" ? :none : :lax
}
