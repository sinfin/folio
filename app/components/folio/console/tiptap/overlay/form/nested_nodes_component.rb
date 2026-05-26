# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::Form::NestedNodesComponent < Folio::Console::ApplicationComponent
  def initialize(f:, key:, attr_config:)
    @f = f
    @key = key
    @attr_config = attr_config
  end

  private
    def add_button
      render(Folio::Console::Ui::ButtonComponent.new(
        icon: :plus,
        label: t(".add", model: node_class.model_name.human),
        variant: :success,
        size: :sm,
      ))
    end

    def nested_fields_component
      Folio::NestedFieldsComponent.new(f: @f,
                                       key: @key,
                                       add: add_button,
                                       class_name: "f-c-tiptap-overlay-form-nested-nodes__nested-fields",
                                       virtual: {
                                         new_object: node_class.new,
                                         fields_key: :data,
                                       },
                                       duplicate: true)
    end

    def nested_node_item(nested_fields)
      nested_f = nested_fields.g
      nested_node = nested_f.object
      row_key = nested_fields.row_key

      content_tag(:div, class: "f-c-tiptap-overlay-form-nested-nodes__item") do
        safe_join([
          tag.input(type: "hidden", name: nested_node_input_name(row_key, :type), value: nested_node.class.name),
          tag.input(type: "hidden", name: nested_node_input_name(row_key, :version), value: nested_node.version),
          nested_node_item_header(nested_node),
          nested_node_item_fields(nested_f, nested_node),
        ])
      end
    end

    def nested_node_item_header(nested_node)
      content_tag(:div, class: "f-c-tiptap-overlay-form-nested-nodes__item-header") do
        content_tag(:h4,
                    t(".title", model: nested_node.class.model_name.human),
                    class: "f-c-tiptap-overlay-form-nested-nodes__item-title")
      end
    end

    def nested_node_item_fields(nested_f, nested_node)
      content_tag(:div, class: "f-c-tiptap-overlay-form-nested-nodes__item-fields") do
        safe_join(nested_node.class.structure.map do |nested_key, nested_attr_config|
          render(Folio::Console::Tiptap::Overlay::Form::InputComponent.new(
            f: nested_f,
            key: nested_key,
            attr_config: nested_attr_config,
          ))
        end)
      end
    end

    def node_class
      @attr_config[:node_class]
    end

    def label
      @f.object.class.human_attribute_name(@key)
    end

    def nested_node_input_name(ui_key, input_key)
      "#{@f.object_name}[#{@key}][#{ui_key}][#{input_key}]"
    end
end
