# frozen_string_literal: true

# when shared files are enabled, this model restricts usage of specific file to specific sites
class Folio::MediaSourceSiteLink < ApplicationRecord
  belongs_to :media_source, class_name: "Folio::MediaSource"
  belongs_to :site, class_name: "Folio::Site"

  validate :validate_unique_site_for_media_source
  validates :max_usage_count, numericality: { greater_than: 0, allow_nil: true }

  def effective_max_usage_count
    max_usage_count.presence || media_source.max_usage_count
  end

  private
    def validate_unique_site_for_media_source
      return if site_id.blank? || marked_for_destruction?
      return errors.add(:media_source_id, :taken) if active_duplicate_sibling?
      return if media_source_id.blank?
      return unless persisted_duplicate_exists?

      errors.add(:media_source_id, :taken)
    end

    def active_duplicate_sibling?
      return false unless media_source

      media_source.media_source_site_links.any? do |link|
        link != self &&
          !link.marked_for_destruction? &&
          link.site_id == site_id
      end
    end

    def persisted_duplicate_exists?
      self.class
          .where(media_source_id:, site_id:)
          .where.not(id: [id, *destroyed_sibling_ids].compact)
          .exists?
    end

    def destroyed_sibling_ids
      return [] unless media_source

      media_source.media_source_site_links.filter_map do |link|
        link.id if link != self &&
                   link.marked_for_destruction? &&
                   link.site_id == site_id
      end
    end
end
