# frozen_string_literal: true

module Folio
  module Cache
    module ModelConcern
      extend ActiveSupport::Concern

      included do
        attr_accessor :folio_cache_skip_invalidation
        after_commit :folio_cache_invalidate_versions!
      end

      # Public method called by after_commit
      def folio_cache_invalidate_versions!
        return if folio_cache_skip_invalidation
        return unless respond_to?(:site_id) && site_id.present?

        keys = folio_cache_version_keys
        return if keys.empty?

        invalidation_metadata = {
          type: "model",
          class: self.class.base_class.name,
          id: id
        }

        Folio::Cache::Invalidator.invalidate!(site_id:, keys:, invalidation_metadata:)
      rescue StandardError => e
        Rails.logger.error "Folio::Cache::ModelConcern#folio_cache_invalidate_versions! failed for #{self.class.name}##{id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
      end

      # Override in models to specify which cache keys to invalidate
      # Returns array of strings, e.g., ["published", "navigation"]
      def folio_cache_version_keys
        []
      end

      # Helper for publishable models - returns true if currently published
      # OR if publishing status just changed (handles unpublishing case where
      # we need to invalidate caches that previously showed this record)
      def folio_cache_affects_published?
        return false unless respond_to?(:published?)
        return true if published?

        (previous_changes.keys & %w[published published_at published_from published_until]).any?
      end
    end
  end
end
