# frozen_string_literal: true

module Folio::Console::IndexFiltersRangeScopes
  extend ActiveSupport::Concern

  included do
    scope :filter_by_params, -> (filtering_params) do
      if filtering_params.present?
        results = where(nil)
        filtering_params.each do |key, value|
          next if [ :sort, :desc ].include?(key.to_sym)
          next unless results.respond_to?(key)

          if value.present?
            results = results.public_send(key, value)
          end
        end
        results
      else
        where(nil)
      end
    end
  end

  class_methods do
    def folio_console_index_filter_range_scope(attr)
      scope "by_#{attr}_range".to_sym, -> (range_str) do
        from, to = range_str.split(/ ?- ?/)

        runner = self

        if from.present?
          from_date_time = DateTime.parse(from)
          runner = runner.where(attr => from_date_time..)
        end

        if to.present?
          to = "#{to} 23:59" if to.exclude?(":")
          to_date_time = DateTime.parse(to)
          runner = runner.where(attr => ..to_date_time)
        end

        runner
      end
    end
  end
end
