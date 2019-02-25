# frozen_string_literal: true

# Call scopes directly from your URL params:
#
#     @products = Product.filter_by_params(params.slice(:status, :location,:starts_with))
#
module Folio::Filterable
  extend ActiveSupport::Concern
  include PgSearch

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
end
