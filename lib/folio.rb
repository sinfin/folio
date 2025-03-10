# frozen_string_literal: true

require "folio/engine"

require "dotenv-rails"
require "friendly_id"
require "ancestry"
require "devise"
require "devise_invitable"
require "devise-i18n"
require "devise-bootstrap-views"
require "phonelib"
require "cancancan"
require "responders"
require "sitemap_generator"
require "acts-as-taggable-on"
require "pg_search"
require "turbolinks"

require "slim"
require "simple_form"
require "country_select"
require "cocoon"
require "pagy"
require "jquery-rails"
require "dropzonejs-rails"
require "countries"
require "breadcrumbs_on_rails"
require "invisible_captcha"
require "rails-i18n"
require "aasm"
require "recaptcha"
require "audited"
require "fast_jsonapi"
require "traco"
require "aws-sdk-s3"
require "message_bus"
require "terser"
require "premailer"
require "premailer/rails"
require "cells-rails"
require "cells-slim"
require "view_component"
require "vite_rails"

require "dragonfly"
require "dragonfly/s3_data_store"
require "dragonfly_libvips"

module Folio
  LANGUAGES = {
    cs: "CZ",
    sk: "SK",
    de: "DE",
    pl: "PL",
    es: "ES",
    en: "GB",
    en_US: "US"
  }

  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP # Devise.email_regexp
  OG_IMAGE_DIMENSIONS = "1200x630#"

  # respect app/assets/javascripts/folio/message_bus.js
  MESSAGE_BUS_CHANNEL = "folio_messagebus_channel"

  LIGHTBOX_IMAGE_SIZE = "2560x2048>"

  def self.table_name_prefix
    "folio_"
  end

  def self.atoms_previews_stylesheet_path(site:, class_name:)
    site.layout_assets_stylesheets_path
  end

  def self.expires_in
    1.hour
  end
end
