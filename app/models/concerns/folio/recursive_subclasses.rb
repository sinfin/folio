# frozen_string_literal: true

module Folio::RecursiveSubclasses
  extend ActiveSupport::Concern

  module ClassMethods
    def recursive_subclasses(include_self: true, exclude_singletons: false, exclude_abstract: false, preload_sti: true)
      self.preload_sti if preload_sti && self.respond_to?(:preload_sti)

      subs = subclasses.map { |k| k.recursive_subclasses(preload_sti: false) }
                       .flatten

      if exclude_singletons
        subs = subs.reject { |k| k.try(:singleton?) }
      end

      if exclude_abstract
        subs = subs.reject(&:abstract_class?)
      end

      include_self ? [self] + subs.compact : subs.compact
    end

    def recursive_subclasses_for_select(include_self: true, exclude_singletons: true, preload_sti: true, base_as_empty_string: true)
      klass_collection = recursive_subclasses(include_self:,
                                             exclude_singletons:,
                                             preload_sti:)

      type_collection_for_select(klass_collection, base_as_empty_string:)
    end

    def type_collection_for_select(klass_collection, base_as_empty_string: true)
      klass_collection.map do |klass|
        if base_as_empty_string && klass.base_class?
          [klass.model_name.human, ""]
        else
          [klass.model_name.human, klass.to_s]
        end
      end
    end
  end
end
