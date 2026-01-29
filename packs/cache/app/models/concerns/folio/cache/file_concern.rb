# frozen_string_literal: true

module Folio
  module Cache
    module FileConcern
      extend ActiveSupport::Concern
      include ::Folio::Cache::ModelConcern

      def folio_cache_version_keys
        keys = [CACHE_KEYS[:files]]

        file_placements.includes(:placement).each do |file_placement|
          placement = file_placement.placement
          next if placement.blank?
          next unless placement.respond_to?(:folio_cache_version_keys)

          keys.concat(placement.folio_cache_version_keys)
        end

        keys.uniq
      end
    end
  end
end
