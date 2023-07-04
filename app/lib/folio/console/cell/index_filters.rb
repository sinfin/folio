# frozen_string_literal: true

module Folio::Console::Cell::IndexFilters
  def index_filters
    if controller.respond_to?(:index_filters, true)
      controller.send(:index_filters)
    end
  end

  def index_filters_hash
    @index_filters_hash ||= begin
      h = {}

      if index_filters
        index_filters.each do |key, config|
          if config == :date_range
            h[key] = { as: :date_range }
          elsif config.is_a?(Array)
            h[key] = { as: :collection, collection: config }
          elsif config.is_a?(String)
            h[key] = { as: :autocomplete, url: config }
          elsif config.is_a?(Hash)
            h[key] = config
          else
            raise "Invalid index filter type - #{key}"
          end
        end
      end

      h
    end
  end

  def filtered?
    return @filtered unless @filtered.nil?

    @filtered = index_filters_hash.any? do |key, _config|
      filtered_by?(key)
    end
  end

  def filtered_by?(key)
    config = index_filters_hash[key]

    if config[:as] == :hidden
      false
    elsif config[:as] == :numeric_range
      controller.params["#{key}_from"].present? || controller.params["#{key}_to"].present?
    else
      controller.params[key].present?
    end
  end
end
