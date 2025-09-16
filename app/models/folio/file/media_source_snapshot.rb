# frozen_string_literal: true

class Folio::File::MediaSourceSnapshot < Folio::ApplicationRecord
  belongs_to :file, class_name: "Folio::File"

  delegate :media_source, to: :file

  validates :max_usage_count, presence: true, numericality: { greater_than: 0 }
  validates :sites, presence: true

  def sites_display
    site_objects.map(&:title).join(", ")
  end

  def site_objects
    Folio::Site.where(id: sites)
  end

  def can_be_used_on_site?(site)
    sites.include?(site.id)
  end
end

# == Schema Information
#
# Table name: folio_file_media_source_snapshots
#
#  id              :bigint(8)        not null, primary key
#  file_id         :bigint(8)        not null
#  media_source_id :bigint(8)        not null
#  max_usage_count :integer          not null
#  sites           :integer          not null, is an Array
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_folio_file_media_source_snapshots_on_file_id          (file_id)
#  index_folio_file_media_source_snapshots_on_media_source_id  (media_source_id)
#  index_folio_file_media_source_snapshots_on_sites            (sites) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (file_id => folio_files.id)
#  fk_rails_...  (media_source_id => folio_media_sources.id)
#
