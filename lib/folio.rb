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
require "sass-rails"
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

  EMAIL_REGEXP = /[^@]+@[^@]+\.[^@]+/
  OG_IMAGE_DIMENSIONS = "1200x630#"

  # respect app/assets/javascripts/folio/message-bus.js
  MESSAGE_BUS_CHANNEL = "folio_messagebus_channel"

  def self.table_name_prefix
    "folio_"
  end

  def self.current_site(request: nil)
    if Rails.application.config.folio_site_is_a_singleton
      Folio::Site.instance
    else
      fail "You must implement :current_site yourself"
    end
  end

  def self.site_instance_for_mailers
    if Rails.application.config.folio_site_is_a_singleton
      Folio::Site.instance
    else
      Folio::Site.ordered.first
    end
  end

  # set to force authentication via a site
  def self.site_for_crossdomain_devise
    nil
  end

  def self.atoms_previews_stylesheet_path(site:, class_name:)
    site.layout_assets_path
  end
end
