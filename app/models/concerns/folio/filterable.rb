# frozen_string_literal: true

# Call scopes directly from your URL params:
#
#     @products = Product.filter_by_params(params.slice(:status, :location,:starts_with))
#
module Folio::Filterable
  extend ActiveSupport::Concern
  include PgSearch::Model
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
        if type_for_attribute(key.to_s).type == :boolean
          scope "by_#{key}".to_sym, -> (arg) {
            case arg
            when true, 'true'
              where(key => true)
            when false, 'false'
              where(key => [nil, false])
            else
              all
            end
          }
        else
          scope "by_#{key}".to_sym, -> (arg) {
            if arg.present?
              where(key => arg)
            else
              all
            end
          }
        end
      end
    end
  end
end
