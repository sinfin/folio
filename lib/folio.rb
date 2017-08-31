# frozen_string_literal: true

require 'folio/engine'
require 'friendly_id'
require 'ancestry'
require 'devise'
require 'responders'
require 'active_model_serializers'
require 'sitemap_generator'

require 'slim'
require 'sass-rails'
require 'bootstrap-sass'
require 'simple_form'
require 'cocoon'
require 'kaminari'
require 'font-awesome-rails'
require 'jquery-rails'
require 'dropzonejs-rails'
require 'countries'

module Folio
  class Engine < ::Rails::Engine
    config.assets.precompile += %w[folio/console/base.css folio/console/base.js]
  end

  LANGUAGES = {
    cs: 'CZ',
    de: 'DE',
    es: 'ES',
    en: 'US'
  }
end
