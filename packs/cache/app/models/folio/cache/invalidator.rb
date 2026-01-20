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
          site = Folio::Site.find(site_id) if Folio::Cache.expires_at_for_key

          data_to_upsert = keys.map do |key|
            expires_at = Folio::Cache.expires_at_for_key&.call(key:, site:)
            {
              site_id:,
              key:,
              created_at: now,
              updated_at: now,
              expires_at:
            }
          end

          Folio::Cache::Version.upsert_all(
            data_to_upsert,
            unique_by: [:site_id, :key],
            on_duplicate: Arel.sql("updated_at = EXCLUDED.updated_at, expires_at = EXCLUDED.expires_at")
          )
        end
      end
    end
  end
end
