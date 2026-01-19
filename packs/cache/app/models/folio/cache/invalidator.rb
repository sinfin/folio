# frozen_string_literal: true

module Folio
  module Cache
    module Invalidator
      class << self
        # Invalidate cache versions for given site and keys
        # Creates missing versions if they don't exist
        # @param site_id [Integer] the site ID
        # @param keys [Array<String>] array of cache version keys
        def invalidate!(site_id:, keys:)
          return if keys.blank?

          now = Time.current

          # Find which keys don't exist yet and create them
          existing_keys = Folio::Cache::Version
                          .where(site_id:, key: keys)
                          .pluck(:key)
          missing_keys = keys - existing_keys

          if missing_keys.present?
            Folio::Cache::Version.insert_all(
              missing_keys.map do |key|
                {
                  site_id:,
                  key:,
                  created_at: now,
                  updated_at: now
                }
              end
            )
          end

          # Update timestamps for all versions (including newly created ones)
          Folio::Cache::Version
            .where(site_id:, key: keys)
            .update_all(updated_at: now)
        end
      end
    end
  end
end
