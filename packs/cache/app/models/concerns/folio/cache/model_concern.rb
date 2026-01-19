# frozen_string_literal: true

module Folio
  module Cache
    module ModelConcern
      extend ActiveSupport::Concern

      included do
        after_commit :folio_cache_invalidate_versions!
      end

      # Public method called by after_commit
      def folio_cache_invalidate_versions!
        return unless respond_to?(:site_id) && site_id.present?

        keys = folio_cache_version_keys
        return if keys.empty?

        Folio::Cache::Invalidator.invalidate!(site_id:, keys:)
      rescue StandardError => e
        Rails.logger.error "Folio::Cache::ModelConcern#folio_cache_invalidate_versions! failed for #{self.class.name}##{id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
      end

      private
        # Override in models to specify which cache keys to invalidate
        # Returns array of strings, e.g., ["published", "navigation"]
        def folio_cache_version_keys
          []
        end
    end
  end
end
