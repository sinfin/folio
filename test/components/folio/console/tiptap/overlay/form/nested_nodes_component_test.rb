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

  class ManualCardGroup < Folio::Tiptap::Node
    tiptap_node structure: {
      cards: {
        type: :nested_nodes,
        node_class: NestedCard,
        prebuild: false,
      },
    }
  end

  test "prebuilds one nested node row for blank collection" do
    render_nested_nodes_component(CardGroup.new,
                                  attr_config: CardGroup.structure[:cards])

    assert_selector('.f-nested-fields__fields[data-nested-fields-row-key="item_0"]', visible: :all)
    assert_selector('[name="tiptap_node_attrs[data][cards][item_0][type]"][value="Folio::Console::Tiptap::Overlay::Form::NestedNodesComponentTest::NestedCard"]',
                    visible: :all)
    assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"]')
  end

  test "does not prebuild nested node row when disabled" do
    render_nested_nodes_component(ManualCardGroup.new,
                                  attr_config: ManualCardGroup.structure[:cards])

    assert_no_selector('.f-nested-fields__fields[data-nested-fields-row-key="item_0"]', visible: :all)
    assert_selector(".f-nested-fields__template", visible: :all)
    assert_includes(rendered_content, 'name="tiptap_node_attrs[data][cards][f-nested-fields-template-cards][data][title]"')
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

    render_nested_nodes_component(node,
                                  attr_config: CardGroup.structure[:cards])

    assert_selector(".f-c-tiptap-overlay-form-nested-nodes")
    assert_no_selector('[data-controller="f-c-tiptap-overlay-form-nested-nodes"]')
    assert_selector(".f-nested-fields")
    assert_selector('[data-f-nested-fields-virtual-value="true"]')
    assert_selector('[name="tiptap_node_attrs[data][cards][item_0][type]"][value="Folio::Console::Tiptap::Overlay::Form::NestedNodesComponentTest::NestedCard"]',
                    visible: :all)
    assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"][value="First card"]')
    assert_selector('.f-nested-fields__control--duplicate[data-action*="onDuplicateClick"]')
    assert_selector('.f-nested-fields__control--destroy[data-action*="onDestroyClick"]')
    assert_selector(".f-nested-fields__template", visible: :all)
    assert_includes(rendered_content, 'name="tiptap_node_attrs[data][cards][f-nested-fields-template-cards][data][title]"')
    assert_no_selector('[data-controller*="f-tooltip"]')
    assert_no_selector('[data-action*="addNestedNode"]')
  end

  private
    def render_nested_nodes_component(node, attr_config:)
      view = vc_test_controller.view_context

      view.simple_form_for(node, url: "/", as: "tiptap_node_attrs[data]") do |f|
        render_inline(Folio::Console::Tiptap::Overlay::Form::NestedNodesComponent.new(
          f:,
          key: :cards,
          attr_config:,
        ))
      end
    end
end
