# frozen_string_literal: true

module Folio::Deprecation
  def self.log(msg)
    Raven.capture_message(msg) if defined?(Raven)

    if defined?(logger)
      Rails.logger.error(msg)
    else
      puts msg
    end
  end
end
