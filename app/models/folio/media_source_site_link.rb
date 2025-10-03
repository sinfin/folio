# frozen_string_literal: true

class Folio::MediaSourceSiteLink < ApplicationRecord
  belongs_to :media_source, class_name: "Folio::MediaSource"
  belongs_to :site, class_name: "Folio::Site"

  validates :media_source_id, uniqueness: { scope: :site_id }
end

# == Schema Information
#
# Table name: folio_media_source_site_links
#
#  id              :bigint(8)        not null, primary key
#  media_source_id :bigint(8)        not null
#  site_id         :bigint(8)        not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_folio_media_source_site_links_on_media_source_id  (media_source_id)
#  index_folio_media_source_site_links_on_site_id          (site_id)
#  index_folio_media_source_site_links_unique              (media_source_id,site_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (media_source_id => folio_media_sources.id)
#  fk_rails_...  (site_id => folio_sites.id)
#
