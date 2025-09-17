# frozen_string_literal: true

module Folio::File::HasMediaSource
  extend ActiveSupport::Concern

  included do
    belongs_to :media_source, class_name: "Folio::MediaSource", optional: true
    has_many :file_site_links, class_name: "Folio::FileSiteLink", foreign_key: :file_id, dependent: :destroy
    has_many :allowed_sites, through: :file_site_links, source: :site

    before_save :copy_media_source_data, if: :media_source_id_changed?
  end

  def media_source_sites
    return nil unless allowed_sites.any?
    allowed_sites.pluck(:title).join(", ")
  end

  def current_usage_count
    file_placements_size || file_placements.count
  end

  def usage_limit_exceeded?
    return false unless attribution_max_usage_count&.positive?
    current_usage_count >= attribution_max_usage_count
  end

  def can_be_used_on_site?(site)
    return true if media_source.blank?

    if Rails.application.config.folio_shared_files_between_sites
      allowed_sites.include?(site)
    else
      self.site == site
    end
  end

  def console_show_prepended_fields
    fields = super

    fields[:media_source_id] = {}

    fields
  end

  private
    def copy_media_source_data
      return unless media_source && media_source_id_changed?

      if attribution_licence.blank? && media_source.licence.present?
        self.attribution_licence = media_source.licence
      end

      if attribution_copyright.blank? && media_source.copyright_text.present?
        self.attribution_copyright = media_source.copyright_text
      end

      if attribution_max_usage_count.blank? && media_source.max_usage_count.present?
        self.attribution_max_usage_count = media_source.max_usage_count
      end

      file_site_links.destroy_all

      sites_for_file = if Rails.application.config.folio_shared_files_between_sites
        media_source.allowed_sites.any? ? media_source.allowed_sites : [site]
      else
        [site]
      end

      sites_for_file.each do |site_obj|
        file_site_links.build(site: site_obj)
      end
    end
end
