# frozen_string_literal: true

Folio::File.class_eval do
  def folio_cache_version_keys
    keys = %w[folio_files]

    file_placements.includes(:placement).each do |file_placement|
      placement = file_placement.placement
      next if placement.blank?
      next unless placement.respond_to?(:folio_cache_version_keys)

      keys.concat(placement.folio_cache_version_keys)
    end

    keys.uniq
  end
end
