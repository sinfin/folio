# frozen_string_literal: true

module Folio
  module Cache
    module SiteConcern
      extend ActiveSupport::Concern
      include ::Folio::Cache::ModelConcern

      def folio_cache_version_keys
        [CACHE_KEYS[:sites]]
      end
    end
  end
end
