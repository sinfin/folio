# frozen_string_literal: true

source 'https://rubygems.org'

# Declare your gem's dependencies in folio.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
gem 'mini_racer', platforms: :ruby
gem 'premailer', github: 'sinfin/premailer'
gem 'premailer-rails'

gem 'pg', '~> 1'

gem 'actionpack-page_caching', github: 'sinfin/actionpack-page_caching'

group :test do
  gem 'minitest', '5.10.3'
  gem 'factory_bot'
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'faker'
  gem 'rack_session_access'
end

group :development do
  gem 'puma'
  gem 'rack-mini-profiler', require: false
  gem 'i18n-tasks'
  gem 'rubocop', '0.66.0'
end

group :development, :test do
  gem 'byebug'
end
