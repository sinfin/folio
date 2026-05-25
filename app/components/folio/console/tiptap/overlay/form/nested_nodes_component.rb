# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::Form::NestedNodesComponent < Folio::Console::ApplicationComponent
  def initialize(f:, key:, attr_config:)
    @f = f
    @key = key
    @attr_config = attr_config
  end

  private
    def data
      stimulus_controller("f-c-tiptap-overlay-form-nested-nodes").merge(nested_node_key: @key)
    end

    def items
      @f.object.public_send(@key)
    end

    def add_button
      render(Folio::Console::Ui::ButtonComponent.new(
        icon: :plus,
        label: t(".add", model: node_class.model_name.human),
        variant: :success,
        size: :sm,
        data: stimulus_action(click: "addNestedNode"),
      ))
    end

    def nested_node_items
      items.each_with_index.map do |nested_node, index|
        nested_node_item(nested_node:, ui_key: "item_#{index}", index:, count: items.size)
      end
    end

    def nested_node_template
      tag.template(data: stimulus_target("template").merge(nested_node_key: @key)) do
        nested_node_item(nested_node: node_class.new, ui_key: "NEW_RECORD", index: 0, count: 1)
      end
    end

    def nested_node_item(nested_node:, ui_key:, index:, count:)
      content_tag(:div,
                  class: "f-c-tiptap-overlay-form-nested-nodes__item",
                  data: stimulus_target("item").merge(nested_node_ui_key: ui_key)) do
        safe_join([
          tag.input(type: "hidden", name: nested_node_input_name(ui_key, :type), value: nested_node.class.name),
          tag.input(type: "hidden", name: nested_node_input_name(ui_key, :version), value: nested_node.version),
          nested_node_item_header(nested_node, index, count),
          nested_node_item_fields(ui_key, nested_node),
        ])
      end
    end

    def nested_node_item_header(nested_node, index, count)
      content_tag(:div, class: "f-c-tiptap-overlay-form-nested-nodes__item-header") do
        safe_join([
          content_tag(:h4,
                      t(".title", model: nested_node.class.model_name.human, number: index + 1),
                      class: "f-c-tiptap-overlay-form-nested-nodes__item-title",
                      data: stimulus_target("title")),
          content_tag(:div,
                      safe_join(nested_node_buttons(index:, count:)),
                      class: "f-c-tiptap-overlay-form-nested-nodes__item-buttons"),
        ])
      end
    end

    def nested_node_buttons(index:, count:)
      [
        nested_node_button(icon: :arrow_up,
                           title: t(".move_up"),
                           action: "moveNestedNodeUp",
                           disabled: index.zero?),
        nested_node_button(icon: :arrow_down,
                           title: t(".move_down"),
                           action: "moveNestedNodeDown",
                           disabled: index == count - 1),
        nested_node_button(icon: :content_copy, title: t(".duplicate"), action: "duplicateNestedNode"),
        nested_node_button(icon: :delete, title: t(".remove"), action: "removeNestedNode", variant: :danger),
      ]
    end

    def nested_node_button(icon:, title:, action:, variant: :secondary, disabled: false)
      render(Folio::Console::Ui::ButtonComponent.new(
        icon:,
        variant:,
        size: :sm,
        class_name: "f-c-tiptap-overlay-form-nested-nodes__item-button",
        title:,
        aria: { label: title },
        disabled:,
        data: stimulus_merge_data(stimulus_action(click: action), stimulus_tooltip(title)),
      ))
    end

    def nested_node_item_fields(ui_key, nested_node)
      helpers.simple_fields_for(nested_node_data_form_name(ui_key), nested_node) do |nested_f|
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
    end

    def node_class
      @attr_config[:node_class]
    end

    def label
      @f.object.class.human_attribute_name(@key)
    end

    def nested_node_data_form_name(ui_key)
      "#{@f.object_name}[#{@key}][#{ui_key}][data]"
    end

    def nested_node_input_name(ui_key, input_key)
      "#{@f.object_name}[#{@key}][#{ui_key}][#{input_key}]"
    end
end
