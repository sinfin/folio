# frozen_string_literal: true

class Folio::MediaSource < Folio::ApplicationRecord
  include Folio::BelongsToSite

  has_many :media_source_site_links, class_name: "Folio::MediaSourceSiteLink", dependent: :destroy
  has_many :sites, through: :media_source_site_links, class_name: "Folio::Site"
  has_many :files, class_name: "Folio::File", foreign_key: :media_source_id

  accepts_nested_attributes_for :media_source_site_links, allow_destroy: true

  validates :title, presence: true

  before_destroy :check_usage_before_destroy

  scope :ordered, -> { order(id: :desc) }

  scope :by_site_slug, -> (slug) do
    joins(:sites).where(folio_sites: { slug: })
  end

  def self.with_assigned_media_counts
    left_joins(:files)
      .group(:id)
      .select("folio_media_sources.*, COUNT(folio_files.id) as assigned_media_count")
  end

  def assigned_media_count
    # If eager loaded from with_assigned_media_counts, use that value
    if has_attribute?(:assigned_media_count) && attributes["assigned_media_count"].present?
      attributes["assigned_media_count"].to_i
    else
      @assigned_media_count ||= Folio::File.where(media_source_id: id).count
    end
  end

  def indestructible_reason
    return nil unless assigned_media_count.positive?
    I18n.t("folio.media_source.cannot_destroy_with_assigned_media", count: assigned_media_count)
  end

  private
    def check_usage_before_destroy
      if indestructible_reason.present?
        errors.add(:base, indestructible_reason)
        throw(:abort)
      end
    end
end

# == Schema Information
#
# Table name: folio_media_sources
#
#  id              :bigint(8)        not null, primary key
#  title           :string           not null
#  licence         :string
#  copyright_text  :string
#  max_usage_count :integer          default(1)
#  site_id         :bigint(8)        not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
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
