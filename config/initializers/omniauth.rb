# frozen_string_literal: true

require Folio::Engine.root.join("app/models/folio/omniauth") # to load Folio::Omniauth namespace

Folio::Omniauth.setup_providers(Rails.application.config.folio_users_omniauth_providers)

Rails.application.config.action_dispatch.cookies_same_site_protection = lambda { |request|
  request.path == "/users/auth/apple" ? :none : :lax
}
