# frozen_string_literal: true

require 'kaminari'

require 'folio/engine'
require 'friendly_id'
require 'ancestry'
require 'devise'
require 'cancancan'
require 'responders'
require 'active_model_serializers'
require 'sitemap_generator'
require 'acts-as-taggable-on'
require 'pg_search'

require 'cells'
require 'cells-rails'
require 'cells-slim'
require 'slim'
require 'sass-rails'
require 'bootstrap'
require 'simple_form'
require 'cocoon'
require 'kaminari'
require 'font-awesome-rails'
require 'jquery-rails'
require 'dropzonejs-rails'
require 'countries'
require 'breadcrumbs_on_rails'
require 'rails-assets-selectize'
require 'ahoy_matey'

module Folio
  class Engine < ::Rails::Engine
    config.assets.precompile += %w[
      folio/console/base.css
      folio/console/base.js
      folio/console/react/main.js
      folio/console/react/main.css
    ]
  end

  LANGUAGES = {
    cs: 'CZ',
    de: 'DE',
    es: 'ES',
    en: 'GB'
  }
end
