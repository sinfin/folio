# frozen_string_literal: true

module Folio::Cache::PublishableExtension
  extend ActiveSupport::Concern

  class_methods do
    # Returns the next datetime when any record's published status will change
    # Override in submodules for WithDate/Within specifics
    def folio_cache_expires_at(site:)
      nil
    end
  end
end
