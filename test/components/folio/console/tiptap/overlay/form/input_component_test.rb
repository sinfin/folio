# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::Form::InputComponentTest < Folio::Console::ComponentTest
  class Node < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
      url: { type: :url_json, disable_label: true },
      accent_color: :color,
    }
  end

  test "renders input for configured attribute" do
    node = Node.new(title: "Hello")
    view = vc_test_controller.view_context

    view.simple_form_for(node, url: "/", as: "tiptap_node_attrs[data]") do |f|
      render_inline(Folio::Console::Tiptap::Overlay::Form::InputComponent.new(
        f:,
        key: :title,
        attr_config: Node.structure[:title],
      ))
    end

    assert_selector('[name="tiptap_node_attrs[data][title]"][value="Hello"]')
  end

  test "renders url_json input with disabled modal label" do
    node = Node.new(url: { href: "/foo" })
    view = vc_test_controller.view_context

    view.simple_form_for(node, url: "/", as: "tiptap_node_attrs[data]") do |f|
      render_inline(Folio::Console::Tiptap::Overlay::Form::InputComponent.new(
        f:,
        key: :url,
        attr_config: Node.structure[:url],
      ))
    end

    assert_selector('[data-f-c-input-form-group-url-disable-label-value="true"]')
    assert_selector("input[name='tiptap_node_attrs[data][url]'][value='{\"href\":\"/foo\"}']", visible: false)
  end

  test "renders color input" do
    node = Node.new(accent_color: "#ff00aa")
    view = vc_test_controller.view_context

    view.simple_form_for(node, url: "/", as: "tiptap_node_attrs[data]") do |f|
      render_inline(Folio::Console::Tiptap::Overlay::Form::InputComponent.new(
        f:,
        key: :accent_color,
        attr_config: Node.structure[:accent_color],
      ))
    end

    assert_selector('input[type="color"][name="tiptap_node_attrs[data][accent_color]"][value="#ff00aa"]')
  end
end
