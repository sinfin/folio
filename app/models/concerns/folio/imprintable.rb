# frozen_string_literal: true

module Folio::Imprintable
  extend ActiveSupport::Concern

  class_methods do
    # TODO: imprint methods & attributes
    # TODO: white-list attributes
    # TODO: multi-level associations
    def imprints_association(association, include: nil, as: nil)
      method_name = :"imprinted_#{association}"
      imprint_field = :"#{association}_imprint"

      association_class = reflect_on_association(association).klass
      association_type = reflect_on_association(association).macro
      single_association = %i[belongs_to has_one].include?(association_type)
      include = Array(include) unless include.nil?

      serialize imprint_field

      define_method(:"imprint_#{association}") do
        write_attribute(imprint_field, send(association).as_json(include: include))
      end

      define_method(:"imprint_#{association}!") do
        update_columns(
          imprint_field => send(association).as_json(include: include)
        )
      end

      define_method(method_name) do
        return if read_attribute(imprint_field).nil?
        return instance_variable_get("@#{method_name}") if instance_variable_get("@#{method_name}").present?

        imprinted = read_attribute(imprint_field)
        return if imprinted.nil? || imprinted.blank?

        if single_association
          instance_variable_set("@#{method_name}", revive_imprint(association_class,
                                                                  imprinted.deep_symbolize_keys,
                                                                  include))
        else
          instance_variable_set("@#{method_name}", imprinted.map { |hash|
            revive_imprint(association_class,
                           hash.deep_symbolize_keys,
                           include)
          })
        end
      end

      define_method(:revive_imprint) do |klass, hash, include|
        imprinted_model_associations = {}
        include.each do |i|
          imprinted_model_associations[i] = hash.delete(i)
        end
        result = klass.new(hash)

        imprinted_model_associations.each do |k, h|
          result.public_send(k).build(h)
        end

        result
      end

      private :revive_imprint
    end
  end
end
