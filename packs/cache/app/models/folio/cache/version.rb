# frozen_string_literal: true

class Folio::Cache::Version < Folio::ApplicationRecord
  self.table_name = "folio_cache_versions"

  include Folio::BelongsToSite

  validates :key,
            presence: true,
            uniqueness: { scope: :site_id }
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
