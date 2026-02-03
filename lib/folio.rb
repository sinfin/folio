# frozen_string_literal: true

module Folio
  mattr_accessor :enabled_packs
  self.enabled_packs ||= [:cache]

  LANGUAGES = {
    cs: "CZ",
    sk: "SK",
    de: "DE",
    pl: "PL",
    es: "ES",
    en: "GB",
    en_US: "US",
  }.freeze

  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP # Devise.email_regexp
  OG_IMAGE_DIMENSIONS = "1200x630#"

  # respect app/assets/javascripts/folio/message_bus.js
  MESSAGE_BUS_CHANNEL = "folio_messagebus_channel"

  LIGHTBOX_IMAGE_SIZE = "2560x2048>"

  def self.pack_enabled?(name)
    enabled_packs.include?(name.to_sym)
  end

  def self.table_name_prefix
    "folio_"
  end

  def self.atoms_previews_stylesheet_path(site:, class_name:)
    site.layout_assets_stylesheets_path
  end

  def self.expires_in
    1.hour
  end

  def self.configure
    yield self
  end
end

require "folio/engine"

# Load pack Railties early so their initializers are registered before Rails processes them
# This must happen at gem load time, not in an initializer
Folio.enabled_packs.each do |pack_name|
  pack_railtie_path = File.expand_path("../packs/#{pack_name}/lib/folio/#{pack_name}", __dir__)
  require pack_railtie_path if File.exist?("#{pack_railtie_path}.rb")
end

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
require "view_component"
require "active_job/uniqueness/sidekiq_patch"

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
require "premailer"
require "premailer/rails"
require "cells-rails"
require "cells-slim"
require "turbo-rails"

require "dragonfly"
require "dragonfly/s3_data_store"
require "dragonfly_libvips"
