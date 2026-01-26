# frozen_string_literal: true

require_relative "cache/railtie"

module Folio
  module Cache
    DEFAULT_EXPIRES_IN = 1.hour

    mattr_accessor :expires_at_for_key, default: nil

    def self.configure(&block)
      if block.arity == 0
        # Block form for temporary configuration (useful in tests)
        previous_expires_at_for_key = expires_at_for_key
        begin
          yield
        ensure
          self.expires_at_for_key = previous_expires_at_for_key
        end
      else
        # Config form for permanent configuration (initializers)
        yield self
      end
    end
  end
end
