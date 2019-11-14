# frozen_string_literal: true

require 'folio/engine'

# TODO: rm the require

require 'dotenv-rails'
require 'friendly_id'
require 'ancestry'
require 'devise'
require 'devise_invitable'
require 'devise-i18n'
require 'devise-bootstrap-views'
require 'cancancan'
require 'responders'
require 'sitemap_generator'
require 'acts-as-taggable-on'
require 'pg_search'

require 'cells'
require 'cells-rails'
require 'cells-slim'
require 'slim'
require 'sass-rails'
require 'simple_form'
require 'cocoon'
require 'pagy'
require 'jquery-rails'
require 'dropzonejs-rails'
require 'countries'
require 'breadcrumbs_on_rails'
require 'ahoy_matey'
require 'invisible_captcha'
require 'rails-i18n'
require 'aasm'
require 'recaptcha'
require 'audited'
require 'fast_jsonapi'
require 'material_icons'

require 'folio/console/simple_form_inputs/date_time_input'

module Folio
  LANGUAGES = {
    cs: 'CZ',
    de: 'DE',
    pl: 'PL',
    es: 'ES',
    en: 'GB',
    en_US: 'US'
  }

  EMAIL_REGEXP = /[^@]+@[^@]+/
  OG_IMAGE_DIMENSIONS = '1200x630#'

  def self.table_name_prefix
    'folio_'
  end
end
