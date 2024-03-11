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
gem "sprockets", "~> 4.0"
gem "sprockets-rails"

gem "dragonfly_libvips", github: "sinfin/dragonfly_libvips", branch: "more_geometry" # could not be in gemspec, because of GITHUB
# gem "dragonfly_libvips", path: "../dragonfly_libvips"

gem "dragonfly-s3_data_store", github: "sinfin/dragonfly-s3_data_store"

gem "cells-rails", "~> 0.1.5"
gem "cells-slim", "~> 0.0.6" # version 0.1.0 drops Rails support and I was not able to make it work

group :development do
  gem "puma", "< 6"
  gem "i18n-tasks"
end

group :development, :test do
  gem "faker"
  gem "pry-byebug"
end
