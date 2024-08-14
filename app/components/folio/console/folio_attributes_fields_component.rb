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

  def integer_input(g, key: :value)
    g.input key,
            numeral: true,
            label: false,
            wrapper_html: { class: "m-0" },
            as: :numeric,
            input_html: { class: "f-c-folio-attributes-fields__value-input", data: stimulus_action("onIntegerInputChange") }
  end

  def hidden_integer_input(g, key: :value)
    g.hidden_field key, class: "f-c-folio-attributes-fields__value-hidden-input"
  end
end
