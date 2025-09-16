# frozen_string_literal: true

class Folio::MediaSource < ApplicationRecord
  include Folio::BelongsToSite

  has_many :media_source_site_links, class_name: "Folio::MediaSourceSiteLink", dependent: :destroy
  has_many :sites, through: :media_source_site_links, class_name: "Folio::Site"

  accepts_nested_attributes_for :media_source_site_links, allow_destroy: true

  validates :title, presence: true
end

# == Schema Information
#
# Table name: folio_media_sources
#
#  id                   :bigint(8)        not null, primary key
#  title                :string           not null
#  licence              :string
#  copyright_text       :string
#  max_usage_count      :integer          default(1)
#  assigned_media_count :integer          default(0)
#  site_id              :bigint(8)        not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_folio_media_sources_on_site_id  (site_id)
#  index_folio_media_sources_on_title    (title)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#
