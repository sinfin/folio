# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::Form::NestedNodesComponentTest < Folio::Console::ComponentTest
  class NestedCard < Folio::Tiptap::Node
    tiptap_node nested: true,
                structure: {
                   title: :string,
                 }
  end

  class CardGroup < Folio::Tiptap::Node
    tiptap_node structure: {
      cards: {
        type: :nested_nodes,
        node_class: NestedCard,
      },
    }
  end

  test "renders nested node rows and template" do
    node = CardGroup.new(cards: [
      {
        "type" => "Folio::Console::Tiptap::Overlay::Form::NestedNodesComponentTest::NestedCard",
        "version" => 1,
        "data" => {
          "title" => "First card",
        },
      },
    ])
    view = vc_test_controller.view_context

    view.simple_form_for(node, url: "/", as: "tiptap_node_attrs[data]") do |f|
      render_inline(Folio::Console::Tiptap::Overlay::Form::NestedNodesComponent.new(
        f:,
        key: :cards,
        attr_config: CardGroup.structure[:cards],
      ))
    end

    assert_selector(".f-c-tiptap-overlay-form-nested-nodes")
    assert_selector('[data-controller="f-c-tiptap-overlay-form-nested-nodes"]')
    assert_selector('[name="tiptap_node_attrs[data][cards][item_0][type]"][value="Folio::Console::Tiptap::Overlay::Form::NestedNodesComponentTest::NestedCard"]',
                    visible: :all)
    assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"][value="First card"]')
    assert_selector('button[data-action*="f-c-tiptap-overlay-form-nested-nodes#addNestedNode"]')
    assert_selector('template[data-nested-node-key="cards"]', visible: :all)
  end
end
