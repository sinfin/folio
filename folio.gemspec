# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "folio/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "folio"
  s.version     = Folio::VERSION
  s.authors     = ["Sinfin"]
  s.email       = ["info@sinfin.cz"]
  s.homepage    = "http://sinfin.digital"
  s.summary     = "Summary of Folio."
  s.description = "Description of Folio."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "aasm"
  s.add_dependency "acts-as-taggable-on"
  s.add_dependency "after_commit_everywhere"
  s.add_dependency "ancestry"
  s.add_dependency "annotate" # required from task copied from Folio to main_app
  s.add_dependency "audited"
  s.add_dependency "aws-sdk-s3"
  s.add_dependency "babel-transpiler"
  s.add_dependency "breadcrumbs_on_rails"
  s.add_dependency "cancancan"
  s.add_dependency "cocoon"
  s.add_dependency "coffee-rails", "~> 5.0"
  s.add_dependency "countries"
  s.add_dependency "country_select"
  s.add_dependency "devise_invitable"
  s.add_dependency "devise-bootstrap-views"
  s.add_dependency "devise-i18n"
  s.add_dependency "devise"
  # s.add_dependency "discard"
  s.add_dependency "dotenv-rails"
  # s.add_dependency "dragonfly_libvips" # we have our version in Gemfile
  s.add_dependency "dragonfly-s3_data_store"
  # s.add_dependency "dragonfly"
  s.add_dependency "dropzonejs-rails"
  s.add_dependency "fast_jsonapi"
  s.add_dependency "friendly_id"
  s.add_dependency "gibbon" # for mailchimp requests
  s.add_dependency "invisible_captcha"
  s.add_dependency "jquery-rails"
  s.add_dependency "jwt"
  s.add_dependency "message_bus"
  s.add_dependency "multi_exiftool"
  s.add_dependency "mux_ruby", "~> 3.9.0"
  s.add_dependency "nokogiri"
  s.add_dependency "omniauth-facebook"
  s.add_dependency "omniauth-google-oauth2"
  s.add_dependency "omniauth-twitter2"
  s.add_dependency "omniauth-apple"
  s.add_dependency "omniauth-rails_csrf_protection"
  s.add_dependency "omniauth"
  s.add_dependency "pagy"
  s.add_dependency "pg_search", "= 2.3.2"
  s.add_dependency "pg"
  s.add_dependency "phonelib"
  s.add_dependency "premailer-rails"
  s.add_dependency "rails-i18n", "~> 7"
  s.add_dependency "rails", "~> 7"
  s.add_dependency "recaptcha", "4.13.1"
  s.add_dependency "responders"
  s.add_dependency "rubyzip"
  s.add_dependency "sass-rails"
  s.add_dependency "show_for"
  s.add_dependency "httpparty"
  s.add_dependency "sidekiq-cron", "1.8.0"
  s.add_dependency "sidekiq", "~> 6.5"

  s.add_dependency "simple_form"
  s.add_dependency "sitemap_generator"
  # s.add_dependency "cells-slim", "~> 0.1.1" # need to be in Gemfile
  # s.add_dependency "cells-rails", "~> 0.1.5" # need to be in Gemfile
  s.add_dependency "slim-rails" # need to be in Gemfile
  s.add_dependency "slim"
  s.add_dependency "traco"
  s.add_dependency "turbolinks"
  s.add_dependency "uglifier"
  s.add_dependency "whenever"
  s.add_dependency "redis"
  s.add_dependency "terser"

  s.add_development_dependency "better_errors"
  s.add_development_dependency "binding_of_caller" # used by BetterErrors
  s.add_development_dependency "capybara"
  s.add_development_dependency "factory_bot"
  s.add_development_dependency "guard-rubocop"
  s.add_development_dependency "guard-slimlint"
  s.add_development_dependency "letter_opener"
  s.add_development_dependency "minitest"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "rubocop-minitest"
  s.add_development_dependency "rubocop-packaging"
  s.add_development_dependency "rubocop-performance"
  s.add_development_dependency "rubocop-rails"
  s.add_development_dependency "rubocop-rake"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "vcr"
  s.add_development_dependency "webmock"
end
