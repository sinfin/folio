# frozen_string_literal: true

module Folio::Deprecation
  def self.log(msg)
    Sentry.capture_message(msg) if defined?(Sentry)

    if defined?(logger)
      Rails.logger.error(msg)
    else
      puts msg
    end
  end
end
