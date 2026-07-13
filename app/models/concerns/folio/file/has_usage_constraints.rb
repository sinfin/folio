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
        if Rails.application.config.folio_shared_files_between_sites
          with_usage_constraints_site_rule_joins(Folio::Current.site)
            .where(usage_constraints_under_limit_sql(Folio::Current.site))
            .where(usage_constraints_allowed_site_sql(Folio::Current.site))
        else
          where("attribution_max_usage_count IS NULL OR published_usage_count < attribution_max_usage_count")
        end
      when "unusable", "false"
        if Rails.application.config.folio_shared_files_between_sites
          with_usage_constraints_site_rule_joins(Folio::Current.site)
            .where("#{usage_constraints_over_limit_sql(Folio::Current.site)} OR NOT (#{usage_constraints_allowed_site_sql(Folio::Current.site)})")
        else
          where("attribution_max_usage_count > 0 AND published_usage_count >= attribution_max_usage_count")
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

    def with_usage_constraints_site_rule_joins(site)
      joins(
        sanitize_sql_array([
          <<~SQL.squish,
            LEFT JOIN folio_media_sources usage_constraint_media_sources
              ON usage_constraint_media_sources.id = folio_files.media_source_id
            LEFT JOIN folio_media_source_site_links usage_constraint_media_source_site_links
              ON usage_constraint_media_source_site_links.media_source_id = usage_constraint_media_sources.id
             AND usage_constraint_media_source_site_links.site_id = :site_id
          SQL
          { site_id: site.id }
        ])
      )
    end

    def usage_constraints_under_limit_sql(site = nil)
      effective_max = usage_constraints_effective_max_usage_count_sql
      usage_count = usage_constraints_effective_published_usage_count_sql(site)

      "(#{effective_max} IS NULL OR #{usage_count} < #{effective_max})"
    end

    def usage_constraints_over_limit_sql(site = nil)
      effective_max = usage_constraints_effective_max_usage_count_sql
      usage_count = usage_constraints_effective_published_usage_count_sql(site)

      "(#{effective_max} > 0 AND #{usage_count} >= #{effective_max})"
    end

    def usage_constraints_allowed_site_sql(site)
      sanitize_sql_array([
        <<~SQL.squish,
          (
            (
              EXISTS (
                SELECT 1
                  FROM folio_media_source_site_links usage_constraint_any_media_source_site_links
                 WHERE usage_constraint_any_media_source_site_links.media_source_id = folio_files.media_source_id
              )
              AND usage_constraint_media_source_site_links.id IS NOT NULL
            )
            OR
            (
              NOT EXISTS (
                SELECT 1
                  FROM folio_media_source_site_links usage_constraint_any_media_source_site_links
                 WHERE usage_constraint_any_media_source_site_links.media_source_id = folio_files.media_source_id
              )
              AND (
                NOT EXISTS (
                  SELECT 1
                    FROM folio_file_site_links usage_constraint_file_site_links
                   WHERE usage_constraint_file_site_links.file_id = folio_files.id
                )
                OR EXISTS (
                  SELECT 1
                    FROM folio_file_site_links usage_constraint_file_site_links
                   WHERE usage_constraint_file_site_links.file_id = folio_files.id
                     AND usage_constraint_file_site_links.site_id = :site_id
                )
              )
            )
          )
        SQL
        { site_id: site.id }
      ])
    end

    def usage_constraints_effective_max_usage_count_sql
      <<~SQL.squish
        COALESCE(
          usage_constraint_media_source_site_links.max_usage_count,
          usage_constraint_media_sources.max_usage_count,
          folio_files.attribution_max_usage_count
        )
      SQL
    end

    def usage_constraints_effective_published_usage_count_sql(site)
      return "folio_files.published_usage_count" unless site

      <<~SQL.squish
        CASE
          WHEN EXISTS (
            SELECT 1
              FROM folio_media_source_site_links usage_constraint_media_source_rules
             WHERE usage_constraint_media_source_rules.media_source_id = folio_files.media_source_id
          )
          THEN #{Folio::File::PublishedUsageCounter.sql_for_outer_file(site:)}
          ELSE folio_files.published_usage_count
        END
      SQL
    end
  end

  def usage_limit_exceeded?(site: Folio::Current.site)
    max_usage_count = effective_attribution_max_usage_count(site:)
    return false unless max_usage_count&.positive?

    usage_count = if site && allowed_sites_managed_by_media_source?
      published_usage_count_for_site(site)
    else
      published_usage_count
    end

    usage_count >= max_usage_count
  end

  def can_be_used_on_site?(site)
    return true unless site

    if Rails.application.config.folio_shared_files_between_sites
      if allowed_sites_managed_by_media_source?
        media_source.rule_for_site(site).present?
      else
        allowed_sites.empty? || allowed_sites.include?(site)
      end
    else
      true
    end
  end

  def effective_attribution_max_usage_count(site: Folio::Current.site)
    media_source&.effective_max_usage_count(site:) || attribution_max_usage_count
  end

  def max_usage_count_managed_by_media_source?(site: Folio::Current.site)
    media_source&.effective_max_usage_count(site:).present?
  end

  def allowed_sites_managed_by_media_source?
    Rails.application.config.folio_shared_files_between_sites &&
      media_source&.media_source_site_links&.any?
  end

  def published_usage_count_for_site(site)
    return published_usage_count unless site

    Folio::File::PublishedUsageCounter.count(self, site:)
  end

  def allowed_sites_for_usage_constraints
    if allowed_sites_managed_by_media_source?
      media_source.allowed_sites
    else
      allowed_sites
    end
  end

  def should_broadcast_show_reload_message?
    saved_changes.key?("media_source_id")
  end

  private
    def find_media_source_for(attribution_source)
      scope = if Rails.application.config.folio_shared_files_between_sites
        Folio::MediaSource.all
      else
        Folio::MediaSource.by_site(Folio::Current.site)
      end

      scope.find_by(title: attribution_source) ||
        scope.where("LOWER(folio_unaccent(title)) = LOWER(folio_unaccent(?))", attribution_source).first
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
        attribution_licence: media_source.licence,
        attribution_copyright: media_source.copyright_text,
        attribution_max_usage_count: media_source.max_usage_count
      }.each do |file_attr, value|
        if value.present?
          self.send("#{file_attr}=", value)
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
