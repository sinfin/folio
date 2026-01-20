# frozen_string_literal: true

class Folio::Cache::Version < Folio::ApplicationRecord
  self.table_name = "folio_cache_versions"

  include Folio::BelongsToSite

  validates :key,
            presence: true,
            uniqueness: { scope: :site_id }

  class << self
    # Load all cache versions for a site as a hash
    # @param site [Folio::Site] Site to scope lookup
    # @return [Hash<String, Time>] Hash of key => updated_at timestamp
    def versions_hash_for_site(site)
      return {} unless site

      where(site_id: site.id).pluck(:key, :updated_at).to_h
    end

    # Build cache key string from version keys and timestamps
    # @param keys [Array<String>] Cache version keys
    # @param site [Folio::Site] Site to scope lookup
    # @param versions_hash [Hash<String, Time>] Optional pre-loaded versions hash (defaults to Folio::Current.cache_versions_hash)
    # @return [String, nil] Keys with timestamps (e.g., "published-1705678901/navigation-1705678902"), or nil if keys blank or no site
    def cache_key_for(keys:, site:, versions_hash: nil)
      return nil if keys.blank?
      return nil unless site

      versions_hash ||= Folio::Current.cache_versions_hash
      keys.map { |k| "#{k}-#{versions_hash[k]&.to_i || 0}" }.join("/")
    end
  end
end

# == Schema Information
#
# Table name: folio_cache_versions
#
#  id         :bigint(8)        not null, primary key
#  site_id    :bigint(8)        not null
#  key        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_cache_versions_on_site_id          (site_id)
#  index_folio_cache_versions_on_site_id_and_key  (site_id,key) UNIQUE
#
