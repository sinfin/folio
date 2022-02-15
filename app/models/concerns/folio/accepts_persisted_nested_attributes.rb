# frozen_string_literal: true

module Folio::AcceptsPersistedNestedAttributes
  extend ActiveSupport::Concern

  class_methods do
    def accepts_persisted_nested_attributes_for
      %w[]
    end
  end

  def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
    association_name_s = association_name.to_s

    if self.class.accepts_persisted_nested_attributes_for.map(&:to_s).include?(association_name_s)
      reflection = self.class.reflections[association_name_s]
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
