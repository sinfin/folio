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

module Folio
  DEFAULT_ENABLED_PACKS = [].freeze

  mattr_accessor :enabled_packs
  self.enabled_packs = DEFAULT_ENABLED_PACKS.dup

  LANGUAGES = {
    cs: "CZ",
    sk: "SK",
    de: "DE",
    pl: "PL",
    es: "ES",
    en: "GB",
    en_US: "US"
  }.freeze

  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP # Devise.email_regexp
  OG_IMAGE_DIMENSIONS = "1200x630#"

  # respect app/assets/javascripts/folio/message_bus.js
  MESSAGE_BUS_CHANNEL = "folio_messagebus_channel"

  LIGHTBOX_IMAGE_SIZE = "2560x2048>"

  def self.configure
    yield self
  end

  def self.pack_enabled?(name)
    enabled_packs.include?(name.to_sym)
  end

  def self.enabled_pack_assets(type)
    enabled_packs.flat_map { |pack_name| pack_assets(pack_name, type) }
  end

  def self.pack_assets(pack_name, type)
    pack_module = pack_module(pack_name)
    return [] unless pack_module&.respond_to?(:pack_assets)

    Array(pack_module.pack_assets[type.to_sym]).map(&:to_s)
  end

  def self.pack_module(pack_name)
    "Folio::#{pack_name.to_s.camelize}".safe_constantize
  end

  def self.load_enabled_packs!
    enabled_packs.each do |pack_name|
      pack_path = File.expand_path("../packs/#{pack_name}/lib/folio/#{pack_name}", __dir__)
      require pack_path if File.exist?("#{pack_path}.rb")
    end
  end

  def self.table_name_prefix
    "folio_"
  end

  def self.atoms_previews_stylesheet_path(site:, class_name:)
    site.layout_assets_stylesheets_path
  end

  def self.cache_ttl(status: nil)
    ttl = cache_headers_default_ttl
    multiplier = cache_ttl_multiplier

    return 0 if multiplier == 0.0

    ttl = (ttl * multiplier).round if multiplier && multiplier != 1.0 && multiplier > 0.0

    if status.to_i >= 500
      [ttl / 4, 15].max
    else
      ttl
    end
  end

  def self.expires_in
    cache_ttl.seconds
  end

  def self.cache_headers_default_ttl
    if Rails.application.config.respond_to?(:folio_cache_headers_default_ttl) && Rails.application.config.folio_cache_headers_default_ttl
      Rails.application.config.folio_cache_headers_default_ttl.to_i
    else
      15
    end
  end

  def self.cache_ttl_multiplier
    ENV["FOLIO_CACHE_TTL_MULTIPLIER"]&.to_f
  end
end

Folio.load_enabled_packs!
