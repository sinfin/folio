# frozen_string_literal: true

if ENV['RAVEN_DSN'].present? && (Rails.env.production? || Rails.env.staging?)
  require 'raven'

  Raven.configure do |config|
    config.dsn = ENV['RAVEN_DSN']
  end
end
