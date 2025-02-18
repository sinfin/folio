# frozen_string_literal: true

module Folio::FormsHelper
  def folio_nested_fields(f,
                          key,
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
                          destroy_label: nil,
                          &block)
    render(Folio::NestedFieldsComponent.new(f:,
                                            key:,
                                            collection:,
                                            add:,
                                            destroy:,
                                            position:,
                                            class_name:,
                                            application_namespace:,
                                            add_icon:,
                                            add_label:,
                                            destroy_icon:,
                                            destroy_icon_height:,
                                            destroy_label:)) do |c|
      block.call(c.g)
    end
  end

  def folio_attributes_fields(f, klass, character_counter: nil, hint: nil)
    render(Folio::Console::FolioAttributesFieldsComponent.new(f:, klass:, character_counter:, hint:))
  end
end
