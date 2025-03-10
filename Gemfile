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

gem "rack-mini-profiler"

gem "dragonfly_libvips", github: "sinfin/dragonfly_libvips", branch: "more_geometry" # could not be in gemspec, because of GITHUB
# gem "dragonfly_libvips", path: "../dragonfly_libvips"

gem "premailer-rails"

gem "omniauth-facebook"
gem "omniauth-google-oauth2"
gem "omniauth-twitter2"
gem "omniauth-apple"
gem "omniauth-rails_csrf_protection"
gem "omniauth"

group :development do
  gem "puma", "< 6"
  gem "i18n-tasks"
end

group :development, :test do
  gem "faker"
  gem "pry-byebug"
end
