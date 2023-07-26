# frozen_string_literal: true

# Call scopes directly from your URL params:
#
#     @products = Product.filter_by_params(params.slice(:status, :location,:starts_with))
#
module Folio::Filterable
  extend ActiveSupport::Concern
  include PgSearch::Model

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
    def folio_by_scopes_for(*keys)
      keys.each do |key|
        scope "by_#{key}".to_sym, -> (arg) do
          if type_for_attribute(key.to_s).type == :boolean
            case arg
            when true, "true"
              where(key => true)
            when false, "false"
              where(key => [nil, false])
            else
              all
            end
          else
            if arg.present?
              where(key => arg)
            else
              all
            end
          end
        end
      end
    end

    def folio_by_range_scope(attribute)
      scope "by_#{attribute}_range".to_sym, -> (range_str) do
        from, to = range_str.split(/ ?- ?/)

        runner = self

        if from.present?
          from_date_time = DateTime.parse(from)
          runner = runner.where(attribute => from_date_time..)
        end

        if to.present?
          to = "#{to} 23:59" if to.exclude?(":")
          to_date_time = DateTime.parse(to)
          runner = runner.where(attribute => ..to_date_time)
        end

        runner
      end
    end
  end
end
