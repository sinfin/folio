# frozen_string_literal: true

require_relative "cache/railtie"

module Folio
  module Cache
    DEFAULT_EXPIRES_IN = 1.hour

    mattr_accessor :expires_at_for_key, default: nil
    mattr_accessor :default_key_parts, default: -> { [ENV["CURRENT_RELEASE_COMMIT_HASH"], Folio::Current.host].compact }

    def self.configure(&block)
      if block.arity == 0
        # Block form for temporary configuration (useful in tests)
        previous_expires_at_for_key = expires_at_for_key
        previous_default_key_parts = default_key_parts

        begin
          yield
        ensure
          self.expires_at_for_key = previous_expires_at_for_key
          self.default_key_parts = previous_default_key_parts
        end
      else
        # Config form for permanent configuration (initializers)
        yield self
      end
    end

    # Build full cache key with version support
    #
    # @param name [Object] Regular cache key (record, string, array, etc.)
    # @param keys [Array<String>] Cache version keys to include (default: [])
    # @return [Array] Composed cache key array
    def self.full_key(name: {}, keys: [])
      # Build version key from Folio::Cache::Version timestamps
      version_key = Folio::Cache::Version.cache_key_for(keys:, site: Folio::Current.site)

      # Get default key parts
      default_parts = default_key_parts.call

      # Compose the full cache key
      [name, *default_parts, version_key].compact
    end

    # Cache fetch with Folio::Cache::Version support
    #
    # @param name [Object] Regular cache key (record, string, array, etc.)
    # @param keys [Array<String>] Cache version keys to include (default: [])
    # @param options [Hash] Options passed to Rails.cache.fetch (expires_in:, force:, if:, unless:, etc.)
    def self.fetch(name = {}, keys: [], **options, &block)
      return yield unless block_given?
      return yield unless ::Rails.application.config.action_controller.perform_caching

      # Handle if: and unless: options with early return
      # Evaluate the condition (supports boolean, proc)
      if options.key?(:if)
        condition = options[:if]
        condition_result = condition.is_a?(Proc) ? condition.call : condition
        return yield unless condition_result
      end

      if options.key?(:unless)
        condition = options[:unless]
        condition_result = condition.is_a?(Proc) ? condition.call : condition
        return yield if condition_result
      end

      full_key = self.full_key(name:, keys:)

      # Set default expires_in
      options[:expires_in] ||= DEFAULT_EXPIRES_IN

      # Remove if: and unless: from options since we've already handled them
      options = options.except(:if, :unless)

      # Delegate to Rails.cache.fetch
      Rails.cache.fetch(full_key, **options, &block)
    end

    # Check if cache key exists with Folio::Cache::Version support
    #
    # @param name [Object] Regular cache key (record, string, array, etc.)
    # @param keys [Array<String>] Cache version keys to include (default: [])
    # @param options [Hash] Options passed to Rails.cache.exist? (namespace:, etc.)
    # @return [Boolean] Whether the cache key exists
    def self.exist?(name = {}, keys: [], **options)
      return false unless ::Rails.application.config.action_controller.perform_caching

      full_key = self.full_key(name:, keys:)
      Rails.cache.exist?(full_key, **options)
    end
  end
end
