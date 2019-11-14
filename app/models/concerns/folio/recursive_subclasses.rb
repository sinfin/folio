# frozen_string_literal: true

module Folio::RecursiveSubclasses
  extend ActiveSupport::Concern

  module ClassMethods
    def recursive_subclasses(include_self: true,
                             exclude_singletons: false)
      subs = subclasses.map(&:recursive_subclasses)
                       .flatten

      if exclude_singletons
        subs = subs.reject { |k| k.try(:singleton?) }
      end

      include_self ? [self] + subs.compact : subs.compact
    end

    def recursive_subclasses_for_select(include_self: true,
                                        exclude_singletons: true)
      type_collection_for_select(
        recursive_subclasses(include_self: include_self,
                             exclude_singletons: exclude_singletons)
      )
    end

    def type_collection_for_select(type_collection)
      type_collection.map do |type|
        [type.model_name.human, type]
      end
    end
  end
end
