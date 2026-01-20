# frozen_string_literal: true

module Folio
  module Cache
    module CurrentConcern
      extend ActiveSupport::Concern

      included do
        attribute :cache_versions_hash_source
      end

      def cache_versions_hash
        return {} unless site

        self.cache_versions_hash_source ||= Folio::Cache::Version.versions_hash_for_site(site)
      end
    end
  end
end
