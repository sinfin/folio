# frozen_string_literal: true

source "https://rubygems.org"

# Declare your gem's dependencies in folio.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
gem "mini_racer", platforms: :ruby
gem "premailer", github: "sinfin/premailer"
gem "premailer-rails"
gem "rubyzip"
gem "rack-mini-profiler"
gem "turbolinks"
gem "uglifier", ">= 1.3.0"
gem "show_for"
gem "sidekiq"
gem "sprockets-rails"

gem "dragonfly", "1.4.0"
gem "dragonfly-s3_data_store"
gem "dragonfly_libvips", github: "sinfin/dragonfly_libvips", branch: "more_geometry"
# gem "dragonfly_libvips", path: "../dragonfly_libvips"

group :test do
  gem "minitest", "~> 5.14.4"
  gem "factory_bot"
  gem "capybara", "~> 2.13"
end

group :development do
  gem "puma", "< 6"
  gem "i18n-tasks"
end

group :development, :test do
  # Call 'binding.pry' anywhere in the code to stop execution and get a debugger console
  gem "pry-rails"
  gem "pry-byebug"
  gem "faker"
end
