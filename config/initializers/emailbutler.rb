# frozen_string_literal: true

require "emailbutler/adapters/active_record"

Emailbutler.configure do |config|
  config.adapter = Emailbutler::Adapters::ActiveRecord.new
  config.providers = %w[sendgrid]
  config.ui_username = ENV["SMTP_USERNAME"]
  config.ui_password = ENV["SMTP_PASSWORD"]
end
