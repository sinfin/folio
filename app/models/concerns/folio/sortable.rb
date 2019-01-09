# frozen_string_literal: true

module Folio::Sortable
  extend ActiveSupport::Concern

  included do
    def self.sortable_by(*args)
      if args.map { |a| !a.is_a? Symbol }.any?
        raise ArgumentError.new('Only symbols are allowed')
      end

      args.each do |column|
        if self.columns_hash[column.to_s].type == :integer
          scope :"sort_by_#{column}", -> (direction = :asc) {
            order("coalesce(#{column}, -1) #{direction}")
          }
        else
          scope :"sort_by_#{column}", -> (direction = :asc) {
            order(column => direction)
          }
        end
      end
    end
  end
end
