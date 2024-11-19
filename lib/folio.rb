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
require "premailer"
require "premailer/rails"

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

  # overide if needed
  def self.current_site(request: nil, host: nil, controller: nil)
    return Folio.main_site if request.nil? && host.nil?

    domain = host || request.host

    if Rails.env.development?
      slug = domain.delete_suffix(".localhost")
      begin
        Folio::Site.friendly.find(slug)
      rescue ActiveRecord::RecordNotFound
        raise "Could not find site with '#{slug}' slug. Available are #{Folio::Site.pluck(:slug)}"
      end
    else
      Folio::Site.find_by(domain:) || Folio.main_site
    end
  end

  def self.site_instance_for_mailers
    Folio.main_site
  end

  def self.enabled_site_for_crossdomain_devise
    Rails.application.config.folio_crossdomain_devise ? site_for_crossdomain_devise : nil
  end

  def self.site_for_crossdomain_devise
    nil
  end

  # override me at project level
  def self.main_site
    Folio::Site.ordered.first
  end

  def self.atoms_previews_stylesheet_path(site:, class_name:)
    site.layout_assets_stylesheets_path
  end
end
