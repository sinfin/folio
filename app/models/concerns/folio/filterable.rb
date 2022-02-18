# frozen_string_literal: true

# https://gist.github.com/justinweiss/9065666
#
# Call scopes directly from your URL params:
#
#     @products = Product.filter_by_params(params.slice(:status, :location,:starts_with))
#
module Folio::Filterable
  extend ActiveSupport::Concern
  include PgSearch::Model

  module ClassMethods
    # Call the class methods with the same name as the keys in <tt>filtering_params</tt>
    # with their associated values. Most useful for calling named scopes from
    # URL params. Make sure you don't pass stuff directly from the web without
    # whitelisting only the params you care about first!
    def filter_by_params(filtering_params)
      results = self.where(nil) # create an anonymous scope
      filtering_params.each do |key, value|
        next if [ :sort, :desc ].include?(key.to_sym)
        next unless results.respond_to?(key)

        if value.present?
          results = results.public_send(key, value)
        end
      end
      results
    end
  end
end
