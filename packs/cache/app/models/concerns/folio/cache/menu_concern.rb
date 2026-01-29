# frozen_string_literal: true

module Folio
  module Cache
    module MenuConcern
      extend ActiveSupport::Concern
      include ::Folio::Cache::ModelConcern

      def folio_cache_version_keys
        [CACHE_KEYS[:menus]]
      end
    end
  end
end
