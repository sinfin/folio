# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::Form::InputComponentTest < Folio::Console::ComponentTest
  class Node < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
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
end
