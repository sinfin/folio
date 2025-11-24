# frozen_string_literal: true

module Folio::File::HasUsageConstraints
  extend ActiveSupport::Concern

  included do
    belongs_to :media_source, class_name: "Folio::MediaSource", optional: true
    has_many :file_site_links, class_name: "Folio::FileSiteLink", foreign_key: :file_id, dependent: :destroy
    has_many :allowed_sites, through: :file_site_links, source: :site

    validates :attribution_max_usage_count, numericality: { greater_than: 0, allow_nil: true }

    before_save :handle_attribution_source_changes
    after_save :broadcast_show_reload_if_needed

    scope :by_usage_constraints, -> (constraint_status) do
      case constraint_status
      when "usable", "true"
        usable_by_limit = where("attribution_max_usage_count IS NULL OR published_usage_count < attribution_max_usage_count")

        if Rails.application.config.folio_shared_files_between_sites
          usable_by_limit.where(
            "NOT EXISTS (SELECT 1 FROM folio_file_site_links WHERE folio_file_site_links.file_id = folio_files.id) OR EXISTS (SELECT 1 FROM folio_file_site_links WHERE folio_file_site_links.file_id = folio_files.id AND folio_file_site_links.site_id = ?)",
            Folio::Current.site.id
          )
        else
          usable_by_limit
        end
      when "unusable", "false"
        unusable_by_limit = where("attribution_max_usage_count > 0 AND published_usage_count >= attribution_max_usage_count")

        # Files are unusable if:
        # 1. Usage limit exceeded (published_usage_count >= attribution_max_usage_count)
        # 2. File has site restrictions, but the current site is not in the allowed list
        if Rails.application.config.folio_shared_files_between_sites
          where("(attribution_max_usage_count > 0 AND published_usage_count >= attribution_max_usage_count) OR " \
                "(media_source_id IS NOT NULL AND EXISTS (SELECT 1 FROM folio_file_site_links WHERE folio_file_site_links.file_id = folio_files.id) AND NOT EXISTS (SELECT 1 FROM folio_file_site_links WHERE folio_file_site_links.file_id = folio_files.id AND folio_file_site_links.site_id = ?))",
                Folio::Current.site.id)

        else
          unusable_by_limit
        end
      else
        none
      end
    end

    scope :by_allowed_site, -> (site) do
      left_joins(:allowed_sites).where(
        "folio_sites.id IS NULL OR folio_sites.id = ?",
        site.id
      )
    end

    scope :by_allowed_site_slug, -> (slug) do
      left_joins(:allowed_sites).where(
        "folio_sites.slug = ?",
        slug
      )
    end

    scope :by_media_source, -> (media_source_id) do
      joins(:media_source).where(folio_media_sources: { id: media_source_id })
    end

    def self.usage_constraints_for_select
      [
        [I18n.t(".activerecord.attributes.folio/file.usage_constraints/usable"), "usable"],
        [I18n.t(".activerecord.attributes.folio/file.usage_constraints/unusable"), "unusable"],
      ]
    end
  end

  class_methods do
    def has_usage_constraints?
      true
    end
  end

  def usage_limit_exceeded?
    return false unless attribution_max_usage_count&.positive?
    published_usage_count >= attribution_max_usage_count
  end

  def can_be_used_on_site?(site)
    if Rails.application.config.folio_shared_files_between_sites
      allowed_sites.empty? || allowed_sites.include?(site)
    else
      true
    end
  end

  def should_broadcast_show_reload_message?
    saved_changes.key?("media_source_id")
  end

  private
    def find_media_source_for(attribution_source)
      if Rails.application.config.folio_shared_files_between_sites
        Folio::MediaSource.find_by(title: attribution_source)
      else
        Folio::MediaSource.by_site(Folio::Current.site)
                           .find_by(title: attribution_source)
      end
    end

    def handle_attribution_source_changes
      if attribution_source_changed?
        if attribution_source.present?
          found_media_source = find_media_source_for(attribution_source)

          if found_media_source
            self.media_source = found_media_source
          elsif media_source.present?
            # attribution_source changed to something that does not map to Folio::MediaSource
            # -> remove link
            self.media_source = nil
          end
        elsif media_source.present?
          # attribution_source cleared -> remove link
          self.media_source = nil
        end
      end

      if media_source && media_source_id_changed?
        copy_media_source_data
      end
    end

    def copy_media_source_data
      {
        attribution_licence: :licence,
        attribution_copyright: :copyright_text,
        attribution_max_usage_count: :max_usage_count
      }.each do |file_attr, media_source_attr|
        if media_source.send(media_source_attr).present?
          self.send("#{file_attr}=", media_source.send(media_source_attr))
        end
      end

      if Rails.application.config.folio_shared_files_between_sites
        file_site_links.destroy_all

        media_source.allowed_sites.each do |site_obj|
          file_site_links.build(site: site_obj)
        end
      end
    end

    def broadcast_show_reload_if_needed
      return unless should_broadcast_show_reload_message?
      return unless defined?(MessageBus) && Folio::Current.user

      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                          {
                            type: "f-c-files-show:reload",
                            data: { id: id },
                          }.to_json,
                          user_ids: [Folio::Current.user.id]
    end
end
