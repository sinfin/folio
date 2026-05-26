# frozen_string_literal: true

class Folio::NestedFieldsComponent < Folio::ApplicationComponent
  attr_reader :g, :row_index, :row_key

  bem_class_name :fully_draggable

  def initialize(f:,
                 key:,
                 collection: nil,
                 add: true,
                 destroy: true,
                 position: true,
                 fully_draggable: false,
                 class_name: nil,
                 fields_wrap_class_name: nil,
                 application_namespace: nil,
                 add_icon: nil,
                 add_label: nil,
                 destroy_icon: :close,
                 destroy_icon_height: 24,
                 destroy_label: nil,
                 virtual: nil,
                 duplicate: false)
    @f = f
    @key = key
    @virtual = virtual
    @collection = collection || default_collection
    @add = add
    @destroy = destroy
    @position = position
    @fully_draggable = fully_draggable
    @class_name = class_name
    @fields_wrap_class_name = fields_wrap_class_name
    @application_namespace = application_namespace
    @add_icon = add_icon
    @add_label = add_label
    @destroy_icon = destroy_icon
    @destroy_icon_height = destroy_icon_height
    @destroy_label = destroy_label
    @duplicate = duplicate
  end

  def data
    stimulus_controller("f-nested-fields",
                        values: {
                          key: @key,
                          sortableBound: false,
                          virtual: virtual?,
                        },
                        action: {
                          "f-nested-fields:addMultipleWithAttributes" => "onAddMultipleWithAttributesTrigger",
                          "f-nested-fields:removeFields" => "onRemoveFieldsTrigger",
                        })
  end

  def new_object
    if virtual?
      @virtual.fetch(:new_object)
    else
      @f.object.class.reflect_on_association(@key).klass.new
    end
  end

  def virtual?
    @virtual.present?
  end

  def virtual_fields_key
    @virtual.fetch(:fields_key)
  end

  def fields_name(row_key)
    if virtual?
      "#{@key}][#{row_key}][#{virtual_fields_key}"
    else
      @key
    end
  end

  def fields_options(row_key)
    virtual? ? {} : { child_index: row_key }
  end

  def row_key_for(index)
    "item_#{index}"
  end

  def template_row_key
    "f-nested-fields-template-#{@key}"
  end

  def supports_position?(object)
    return false unless @position

    virtual? || object.respond_to?(:position)
  end

  def controls(supports_position, destroyed: false)
    return if @destroy.blank? && !supports_position && !@duplicate

    content_tag(:div, class: "f-nested-fields__controls") do
      safe_join([
        destroy_control(destroyed:),
        duplicate_control,
        position_hidden_field(supports_position),
        position_control(:arrow_up, "onPositionUpClick", supports_position),
        sortable_handle_control(supports_position),
        position_control(:arrow_down, "onPositionDownClick", supports_position),
      ].compact)
    end
  end

  def application_namespace
    @application_namespace.presence || Rails.application.class.name.deconstantize
  end

  def add_button
    label = @add_label || t(".add")
    klass = in_console? ? nil : "#{application_namespace}::Ui::ButtonComponent".safe_constantize

    if klass
      render(klass.new(tag: :button,
                       label:,
                       variant: :secondary,
                       class_name: "btn-success f-nested-fields__add-button",
                       icon: @add_icon.present? ? @add_icon : nil))
    else
      content_tag(:button,
                  label,
                  class: "btn btn-success f-nested-fields__add-button",
                  type: "button")
    end
  end

  def destroy_icon
    klass = in_console? ? nil : "#{application_namespace}::Ui::IconComponent".safe_constantize

    if klass
      render(klass.new(name: @destroy_icon,
                       height: @destroy_icon_height,
                       class_name: "f-nested-fields__destroy-ico"))
    else
      folio_icon(@destroy_icon,
                 height: @destroy_icon_height,
                 class: "f-nested-fields__destroy-ico")
    end
  end

  def in_console?
    return @in_console if defined?(@in_console)

    @in_console = if controller.is_a?(Folio::Console::BaseController)
      true
    elsif controller.request.path.start_with?("/console")
      true
    else
      false
    end
  end

  private
    def default_collection
      collection = @f.object.send(@key)
      return collection if virtual?

      collection.sort do |a, b|
        if a.respond_to?(:position) && b.respond_to?(:position)
          a.position <=> b.position
        else
          0
        end
      end
    end

    def destroy_control(destroyed:)
      return if @destroy.blank?

      safe_join([
        destroy_hidden_field(destroyed:),
        content_tag(:div,
                    destroy_control_content,
                    class: "f-nested-fields__control f-nested-fields__control--destroy",
                    data: stimulus_action(click: "onDestroyClick")),
      ].compact)
    end

    def destroy_hidden_field(destroyed:)
      return if virtual?

      @g.hidden_field :_destroy,
                      class: "f-nested-fields__destroy-input",
                      value: destroyed ? "1" : nil
    end

    def destroy_control_content
      if @destroy == true
        parts = [destroy_icon]

        if @destroy_label.present?
          parts << content_tag(:div,
                               @destroy_label,
                               class: "f-nested-fields__destroy-label")
        end

        safe_join(parts)
      else
        @destroy.to_s.html_safe
      end
    end

    def position_hidden_field(supports_position)
      return unless supports_position
      return if virtual?

      @g.hidden_field :position, class: "f-nested-fields__position-input"
    end

    def position_control(icon, action, supports_position)
      return unless supports_position

      content_tag(:div,
                  folio_icon(icon, height: 24),
                  class: "f-nested-fields__control f-nested-fields__control--arrow",
                  data: stimulus_action(click: action))
    end

    def duplicate_control
      return unless @duplicate

      content_tag(:div,
                  folio_icon(:content_copy, height: 24, class_name: "f-nested-fields__duplicate-icon"),
                  class: "f-nested-fields__control f-nested-fields__control--duplicate",
                  data: stimulus_action(click: "onDuplicateClick"))
    end

    def sortable_handle_control(supports_position)
      return unless supports_position

      content_tag(:div,
                  folio_icon(:drag, height: 24),
                  class: "f-nested-fields__control f-nested-fields__control--sortable-handle",
                  data: stimulus_target("sortableHandle"))
    end
end
