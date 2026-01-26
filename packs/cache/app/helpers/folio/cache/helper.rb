# frozen_string_literal: true

module Folio
  module Cache
    module Helper
      # Fragment cache helper with Folio::Cache::Version support
      #
      # @param name [Object] Regular cache key (record, string, array, etc.)
      # @param keys [Array<String>] Cache version keys to include (default: [])
      # @param options [Hash] Options passed to Rails cache helper (if:, unless:, expires_in:, etc.)
      def folio_cache(name = {}, keys: [], **options, &block)
        return yield unless block_given?

        full_key = Folio::Cache.full_key(name:, keys:)

        # Set default expires_in
        options[:expires_in] ||= Folio::Cache::DEFAULT_EXPIRES_IN

        # Delegate to Rails cache helper (use helpers.cache for ViewComponent compatibility)
        if respond_to?(:helpers)
          helpers.cache(full_key, **options, &block)
        else
          cache(full_key, **options, &block)
        end
      end
    end
  end
end
