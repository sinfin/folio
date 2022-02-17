# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'folio/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'folio'
  s.version     = Folio::VERSION
  s.authors     = ['Sinfin']
  s.email       = ['info@sinfin.cz']
  s.homepage    = 'http://sinfin.digital'
  s.summary     = 'Summary of Folio.'
  s.description = 'Description of Folio.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'rails', '~> 5.2.1'
  s.add_dependency 'pg', '~> 1.2.3'
  s.add_dependency 'pg_search'
  s.add_dependency 'friendly_id', '~> 5.4.0'
  s.add_dependency 'ancestry'
  s.add_dependency 'carrierwave'
  s.add_dependency 'mini_magick'
  s.add_dependency 'sidekiq'
  s.add_dependency 'slim'
  s.add_dependency 'simple_form'
  s.add_dependency 'cocoon'
  s.add_dependency 'devise'
  s.add_dependency 'cancancan', '~> 2.0'
  s.add_dependency 'sass-rails'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'pagy', '~> 3'
  s.add_dependency 'responders'
  s.add_dependency 'active_model_serializers', '~> 0.9.6'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'dropzonejs-rails'
  s.add_dependency 'sitemap_generator'
  s.add_dependency 'whenever'
  s.add_dependency 'dotenv-rails'
  s.add_dependency 'mailchimp-api'
  s.add_dependency 'invisible_captcha'
  s.add_dependency 'countries'
  s.add_dependency 'acts-as-taggable-on', '~> 6.0'
  s.add_dependency 'breadcrumbs_on_rails', '~> 3'
  s.add_dependency 'cells'
  s.add_dependency 'cells-rails', '0.0.9'
  s.add_dependency 'cells-slim', '0.0.6'
  s.add_dependency 'ahoy_matey', '~> 2'
  s.add_dependency 'rails-i18n'
  s.add_dependency 'state_machines-activerecord'
  s.add_dependency 'actionpack-page_caching'
  s.add_dependency 'recaptcha', '4.13.1'
  s.add_dependency 'nokogiri'

  s.add_dependency 'dragonfly'
  s.add_dependency 'dragonfly-s3_data_store'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'devise-i18n'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'rubocop-rails_config'
  s.add_development_dependency 'guard-rubocop'
  s.add_development_dependency 'guard-coffeelint'
  s.add_development_dependency 'guard-slimlint'
  s.add_development_dependency 'annotate'
  s.add_development_dependency 'letter_opener'
  s.add_development_dependency 'better_errors'
end
