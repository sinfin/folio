# frozen_string_literal: true

module Folio
  module RecursiveSubclasses
    extend ActiveSupport::Concern

    module ClassMethods
      def recursive_subclasses(include_self: true)
        subs = subclasses.map { |sub| sub.recursive_subclasses }.flatten
        if include_self
          [self] + subs
        else
          subs
        end
      end

      def recursive_subclasses_for_select(include_self: true)
        type_collection_for_select(
          recursive_subclasses(include_self: include_self)
        )
      end

      def type_collection_for_select(type_collection)
        type_collection.map do |type|
          [type.model_name.human, type]
        end
      end
    end
  end
end
