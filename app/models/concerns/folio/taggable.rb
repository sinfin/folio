# frozen_string_literal: true

module Folio::Taggable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable
    acts_as_taggable_tenant :site_id

    scope :by_tag, -> (tag) { tagged_with(tag) }

    ActsAsTaggableOn::Tag.class_eval do
      scope :by_site, -> (site) {
        joins(:taggings)
          .where(taggings: { tenant: site.id })
          .select("DISTINCT ON (tags.name) tags.*")
          .reorder("tags.name, tags.taggings_count")
      }
    end
  end
end
