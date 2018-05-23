# frozen_string_literal: true

source 'https://rubygems.org'
source 'https://rails-assets.org'

# Declare your gem's dependencies in folio.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
gem 'therubyracer', platforms: :ruby

group :test do
  gem 'minitest', '5.10.3'
  gem 'factory_girl_rails'
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'faker'
end

group :development do
  gem 'puma'
  gem 'rack-mini-profiler', require: false
end

# To use a debugger
# gem 'byebug', group: [:development, :test]
