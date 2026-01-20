# frozen_string_literal: true

module Folio::Cache::PublishableWithinExtension
  extend ActiveSupport::Concern

  class_methods do
    def folio_cache_expires_at(site:)
      scope = all
      scope = scope.where(site_id: site.id) if try(:has_belongs_to_site?) && site

      now = Time.current

      # Find earliest of:
      # - published_from in the future (content will become visible)
      # - published_until in the future (content will become hidden)
      [
        scope.where("published_from > ?", now).minimum(:published_from),
        scope.where(published: true).where("published_until > ?", now).minimum(:published_until)
      ].compact.min
    end
  end
end
