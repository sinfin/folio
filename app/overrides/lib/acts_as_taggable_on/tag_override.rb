# frozen_string_literal: true

ActsAsTaggableOn::Tag.class_eval do
  include PgSearch::Model
  include Folio::ToLabel

  pg_search_scope :by_query,
                  against: %i[name],
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  scope :ordered, -> { order(name: :asc) }

  scope :by_site, -> (site) {
    tenant_site_ids = [site]
    if Rails.application.config.folio_shared_files_between_sites
      tenant_site_ids << Folio::Current.main_site&.id
    end

    joins(:taggings).where(taggings: { tenant: tenant_site_ids.compact.uniq })
                    .select("DISTINCT ON (tags.name) tags.*")
                    .reorder("tags.name, tags.taggings_count")
  }
end
