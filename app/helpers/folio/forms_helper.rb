# frozen_string_literal: true

module Folio::FormsHelper
  def folio_nested_fields(f,
                          key,
                          collection: nil,
                          add: true,
                          destroy: true,
                          fully_draggable: false,
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
                                            fully_draggable:,
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

  def form_header(f, opts = {}, &block)
    if block_given?
      opts[:right] = capture(&block)
    end

    render(Folio::Console::Form::HeaderComponent.new(f: f,
                                                    title: opts[:title],
                                                    title_class_name: opts[:title_class_name],
                                                    subtitle: opts[:subtitle],
                                                    left: opts[:left],
                                                    right: opts[:right],
                                                    sti_badge: opts[:sti_badge],
                                                    tabs: opts[:tabs],
                                                    hide_fix_error_btn: opts[:hide_fix_error_btn]))
  end
end
