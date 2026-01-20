# frozen_string_literal: true

class Folio::Cache::Version < Folio::ApplicationRecord
  self.table_name = "folio_cache_versions"

  include Folio::BelongsToSite

  validates :key,
            presence: true,
            uniqueness: { scope: :site_id }

  class << self
    # Build cache key string from version keys and timestamps
    # @param keys [Array<String>] Cache version keys
    # @param site [Folio::Site] Site to scope lookup
    # @return [String, nil] Keys with timestamps (e.g., "published-1705678901/navigation-1705678902"), or nil if keys blank or no site
    def cache_key_for(keys:, site:)
      return nil if keys.blank?
      return nil unless site

      versions = where(site_id: site.id, key: keys)
                   .pluck(:key, :updated_at)
                   .to_h

      keys.map { |k| "#{k}-#{versions[k]&.to_i || 0}" }.join("/")
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
