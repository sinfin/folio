# frozen_string_literal: true

module Folio::AcceptsPersistedNestedAttributes
  extend ActiveSupport::Concern

  class_methods do
    def accepts_persisted_nested_attributes_for
      %i[]
    end
  end

  def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
    if self.class.accepts_persisted_nested_attributes_for.include?(association_name)
      reflection = self.class.reflections[association_name.to_s]
      reflection_klass = reflection.options[:class_name].constantize

      attributes_collection.each do |key, attrs|
        if pa = reflection_klass.where(reflection.options[:as] => nil).find_by(id: attrs["id"])
          self.private_attachments << pa
        end
      end

      super(association_name, attributes_collection)
    else
      super
    end
  end
end
