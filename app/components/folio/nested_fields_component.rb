# frozen_string_literal: true

class Folio::NestedFieldsComponent < Folio::ApplicationComponent
  attr_reader :g

  def initialize(f:,
                 key:,
                 collection: nil,
                 add: true,
                 destroy: true,
                 position: true,
                 class_name: nil,
                 application_namespace: nil,
                 add_icon: nil,
                 add_label: nil,
                 destroy_icon: :close,
                 destroy_icon_height: 24,
                 destroy_label: nil)
    @f = f
    @key = key
    @collection = collection || @f.object.send(@key).sort do |a, b|
      if a.respond_to?(:position) && b.respond_to?(:position)
        a.position <=> b.position
      else
        0
      end
    end
    @add = add
    @destroy = destroy
    @position = position
    @class_name = class_name
    @application_namespace = application_namespace
    @add_icon = add_icon
    @add_label = add_label
    @destroy_icon = destroy_icon
    @destroy_icon_height = destroy_icon_height
    @destroy_label = destroy_label
  end

  def data
    stimulus_controller("f-nested-fields",
                        values: {
                          key: @key,
                          sortableBound: false,
                        },
                        action: {
                          "f-nested-fields:addMultipleWithAttributes" => "onAddMultipleWithAttributesTrigger",
                          "f-nested-fields:removeFields" => "onRemoveFieldsTrigger",
                        })
  end

  def new_object
    @f.object.class.reflect_on_association(@key).klass.new
  end

  def application_namespace
    @application_namespace.presence || Rails.application.class.name.deconstantize
  end

  def add_button
    label = @add_label || t(".add")
    klass = "#{application_namespace}::Ui::ButtonComponent".safe_constantize

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
    klass = "#{application_namespace}::Ui::IconComponent".safe_constantize

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
end
