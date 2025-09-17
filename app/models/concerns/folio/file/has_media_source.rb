# frozen_string_literal: true

module Folio::File::HasMediaSource
  extend ActiveSupport::Concern

  included do
    belongs_to :media_source, class_name: "Folio::MediaSource", optional: true
    has_many :file_site_links, class_name: "Folio::FileSiteLink", foreign_key: :file_id, dependent: :destroy
    has_many :allowed_sites, through: :file_site_links, source: :site

    before_save :handle_attribution_source_changes
    after_save :broadcast_show_reload_if_needed
  end

  def media_source_sites
    return nil unless allowed_sites.any?
    allowed_sites.pluck(:title).join(", ")
  end

  def usage_limit_exceeded?
    return false unless attribution_max_usage_count&.positive?
    usage_count >= attribution_max_usage_count
  end

  def can_be_used_on_site?(site)
    return true if media_source.blank?

    if Rails.application.config.folio_shared_files_between_sites
      allowed_sites.empty? || allowed_sites.include?(site)
    else
      self.site == site
    end
  end

  def should_broadcast_show_reload_message?
    saved_changes.key?("media_source_id")
  end

  private
    def handle_attribution_source_changes
      if attribution_source_changed?
        if attribution_source.present?
          if Rails.application.config.folio_shared_files_between_sites
            found_media_source = Folio::MediaSource.accessible_by(Folio::Current.ability)
                                                   .find_by(title: attribution_source)
          else
            found_media_source = Folio::MediaSource.by_site(Folio::Current.site)
                                                   .accessible_by(Folio::Current.ability)
                                                   .find_by(title: attribution_source)
          end

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
        if self.send(file_attr).blank? && media_source.send(media_source_attr).present?
          self.send("#{file_attr}=", media_source.send(media_source_attr))
        end
      end

      if Rails.application.config.folio_shared_files_between_sites && file_site_links.empty?
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
