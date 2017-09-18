# frozen_string_literal: true

module Folio
  module Sortable
    extend ActiveSupport::Concern

    module ClassMethods
      # FIXME: whitelist columns
      # TODO: prefer scopes
      def user_sort(column, descending)
        if column
          method = "order_by_#{column}"
          direction = descending ? :desc : :asc

          if respond_to?(method)
            order("coalesce(#{column}, -1) #{direction}")
          else
            if column =~ /at|order_number$/
              order(column => direction)
            else
              order("coalesce(#{column}, 0) #{direction}")
            end
          end
        else
          where(nil)
        end
      end
    end
  end
end
