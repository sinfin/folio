# frozen_string_literal: true

module Folio::File::HasMediaSource
  extend ActiveSupport::Concern

  included do
    belongs_to :media_source, class_name: "Folio::MediaSource", optional: true
    has_one :media_source_snapshot,
            class_name: "Folio::File::MediaSourceSnapshot",
            foreign_key: :file_id,
            dependent: :destroy

    attribute :max_usage_count, :string

    after_update :create_media_source_snapshot, if: :saved_change_to_media_source_id?
  end

  def max_usage_count
    # Return virtual attribute if set (for JSON responses), otherwise from snapshot
    super.presence || media_source_snapshot&.max_usage_count
  end

  def max_usage_count=(value)
    if media_source_snapshot
      media_source_snapshot.update(max_usage_count: value)
    end
    # Set virtual attribute for JSON serialization
    super(value&.to_s)
  end

  def media_source_sites
    return nil unless media_source_snapshot&.sites&.any?

    site_ids = media_source_snapshot.sites
    Folio::Site.where(id: site_ids).pluck(:title).join(", ")
  end

  def increment_usage!
    if media_source_snapshot&.max_usage_count
      current_usage = usage_count || 0
      if current_usage >= media_source_snapshot.max_usage_count
        errors.add(:base, "Usage limit exceeded")
        return false
      end
    end

    increment!(:usage_count)
  end

  def can_be_used_on_site?(site)
    return true unless media_source_snapshot&.sites&.any?

    media_source_snapshot.can_be_used_on_site?(site)
  end

  def console_show_prepended_fields
    fields = super

    fields[:media_source_id] = {}

    fields
  end

  def self.console_additional_permitted_params
    [:max_usage_count]
  end

  private
    def create_media_source_snapshot
      return unless media_source_id && media_source

      media_source_snapshot&.destroy

      sites_for_snapshot = if Rails.application.config.folio_shared_files_between_sites
        media_source.sites.any? ? media_source.sites.pluck(:id) : [site_id]
      else
        [site_id]
      end

      create_media_source_snapshot!(
        max_usage_count: media_source.max_usage_count,
        sites: sites_for_snapshot
      )
    end
end
