# frozen_string_literal: true

module Folio::Cache::PublishableWithDateExtension
  extend ActiveSupport::Concern

  class_methods do
    def folio_cache_expires_at(site:)
      scope = all
      scope = scope.where(site_id: site.id) if try(:has_belongs_to_site?) && site

      # Find next scheduled publish_at in the future
      scope
        .where(published: true)
        .where("published_at > ?", Time.current)
        .minimum(:published_at)
    end
  end
end
