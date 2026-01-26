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

        # Handle if: and unless: options with early return
        # Evaluate the condition (supports boolean, proc, symbol)
        if options.key?(:if)
          condition = options[:if]
          condition_result = condition.is_a?(Proc) ? instance_exec(&condition) : (condition.is_a?(Symbol) ? send(condition) : condition)
          return yield unless condition_result
        end

        if options.key?(:unless)
          condition = options[:unless]
          condition_result = condition.is_a?(Proc) ? instance_exec(&condition) : (condition.is_a?(Symbol) ? send(condition) : condition)
          return yield if condition_result
        end

        full_key = Folio::Cache.full_key(name:, keys:)

        # Set default expires_in
        options[:expires_in] ||= Folio::Cache::DEFAULT_EXPIRES_IN

        # Remove if: and unless: from options since we've already handled them
        options = options.except(:if, :unless)

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
