# frozen_string_literal: true

class Folio::Console::FolioAttributesFieldsComponent < Folio::Console::ApplicationComponent
  include Folio::Console::FormsHelper

  bem_class_name :character_counter

  def initialize(f:, klass:, character_counter: nil)
    @f = f
    @klass = klass
    @character_counter = character_counter
  end

  def attribute_types
    @attribute_types ||= @klass.ordered.to_a
  end

  def collection
    @collection ||= attribute_types.map do |attribute_type|
      [
        attribute_type.to_label,
        attribute_type.id,
        { data: { data_type: attribute_type.data_type, position: attribute_type.position } },
      ]
    end
  end

  def data
    stimulus_controller("f-c-folio-attributes-fields",
                        action: {
                          "f-nested-fields:add" => "onNestedFieldsAdd",
                        })
  end

  def data_type_disabled?(g, data_type)
    type = g.object.folio_attribute_type || attribute_types.first
    data_type != type.data_type_with_default
  end
end
