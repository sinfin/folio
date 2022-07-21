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

  s.add_dependency "rails", "~> 6.1"
  s.add_dependency "pg", "~> 1.2.3"
  s.add_dependency "pg_search", "= 2.3.2"
  s.add_dependency "friendly_id", "~> 5.3.0"
  s.add_dependency "ancestry", "~> 4.1.0"
  s.add_dependency "mini_racer", "~> 0.4.0"
  s.add_dependency "mini_magick"
  s.add_dependency "sidekiq"
  s.add_dependency "sidekiq-cron"
  s.add_dependency "slim"
  s.add_dependency "simple_form"
  s.add_dependency "country_select"
  s.add_dependency "cocoon"
  s.add_dependency "devise"
  s.add_dependency "devise_invitable"
  s.add_dependency "phonelib"
  s.add_dependency "omniauth", "~> 1.9.1"
  s.add_dependency "omniauth-facebook", "~> 8.0.0"
  s.add_dependency "omniauth-twitter", "~> 1.4.0"
  s.add_dependency "omniauth-google-oauth2", "~> 0.8.1"
  s.add_dependency "cancancan", "~> 3.0"
  s.add_dependency "sass-rails"
  s.add_dependency "coffee-rails", "~> 5.0"
  s.add_dependency "pagy", "~> 3"
  s.add_dependency "responders"
  s.add_dependency "jquery-rails"
  s.add_dependency "dropzonejs-rails"
  s.add_dependency "sitemap_generator"
  s.add_dependency "whenever"
  s.add_dependency "dotenv-rails"
  s.add_dependency "gibbon"
  s.add_dependency "invisible_captcha"
  s.add_dependency "countries"
  s.add_dependency "acts-as-taggable-on", "~> 9.0"
  s.add_dependency "breadcrumbs_on_rails"
  s.add_dependency "cells"
  s.add_dependency "cells-slim", "0.0.6"
  s.add_dependency "cells-rails", "0.1.0"
  s.add_dependency "rails-i18n"
  s.add_dependency "after_commit_everywhere"
  s.add_dependency "aasm"
  s.add_dependency "recaptcha", "4.13.1"
  s.add_dependency "nokogiri"
  s.add_dependency "show_for"
  s.add_dependency "audited", "~> 4.7"
  s.add_dependency "premailer-rails"
  s.add_dependency "fast_jsonapi"
  s.add_dependency "discard"
  s.add_dependency "traco"
  s.add_dependency "uglifier"

  s.add_dependency "dragonfly", "1.3"
  s.add_dependency "dragonfly-s3_data_store"
  s.add_dependency "multi_exiftool"

  s.add_dependency "devise-i18n"
  s.add_dependency "devise-bootstrap-views"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "rubocop-rails_config"
  s.add_development_dependency "rubocop-minitest"
  s.add_development_dependency "rubocop-performance"
  s.add_development_dependency "rubocop-rails"
  s.add_development_dependency "rubocop-rake"
  s.add_development_dependency "guard-rubocop"
  s.add_development_dependency "guard-slimlint"
  s.add_development_dependency "annotate"
  s.add_development_dependency "letter_opener"
  s.add_development_dependency "better_errors"
  s.add_development_dependency "binding_of_caller"
end
