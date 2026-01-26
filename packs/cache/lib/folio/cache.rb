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

    # Cache fetch with Folio::Cache::Version support
    #
    # @param name [Object] Regular cache key (record, string, array, etc.)
    # @param keys [Array<String>] Cache version keys to include (default: [])
    # @param options [Hash] Options passed to Rails.cache.fetch (expires_in:, force:, etc.)
    def self.fetch(name = {}, keys: [], **options, &block)
      return yield unless block_given?
      return yield unless ::Rails.application.config.action_controller.perform_caching

      # Build version key from Folio::Cache::Version timestamps
      version_key = Folio::Cache::Version.cache_key_for(keys:, site: Folio::Current.site)

      # Compose the full cache key
      full_key = [name, version_key].compact

      # Set default expires_in
      options[:expires_in] ||= DEFAULT_EXPIRES_IN

      # Delegate to Rails.cache.fetch
      Rails.cache.fetch(full_key, **options, &block)
    end
  end
end
