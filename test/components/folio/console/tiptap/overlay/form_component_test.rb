# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::FormComponentTest < Folio::Console::ComponentTest
  class NestedCard < Folio::Tiptap::Node
    tiptap_node nested: true,
                structure: {
                   title: :string,
                   content: :text,
                 }

    validates :title,
              presence: true
  end

  class CardGroup < Folio::Tiptap::Node
    tiptap_node structure: {
      cards: {
        type: :nested_nodes,
        node_class: NestedCard,
      },
    }
  end

  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = Dummy::Tiptap::Node::Card.new
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector(".f-c-tiptap-overlay-form")
      end
    end
  end

  test "renders nested node inputs with stable keyed param names" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = CardGroup.new(cards: [
          nested_attrs(title: "First card", content: "Body"),
        ])

        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector('fieldset[data-nested-node-key="cards"]')
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][type]"][value="Folio::Console::Tiptap::Overlay::FormComponentTest::NestedCard"]',
                        visible: :all)
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][version]"][value="1"]',
                        visible: :all)
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"][value="First card"]')
        assert_selector('textarea[name="tiptap_node_attrs[data][cards][item_0][data][content]"]',
                        text: "Body")
        assert_selector('button[data-action*="f-c-tiptap-overlay-form-nested-nodes#addNestedNode"]')
        assert_selector('template[data-nested-node-key="cards"]', visible: :all)
      end
    end
  end

  test "renders nested node field errors" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = CardGroup.new(cards: [
          nested_attrs(title: ""),
        ])
        node.valid?

        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"].is-invalid')
      end
    end
  end

  private
    def nested_attrs(**data)
      {
        "type" => "Folio::Console::Tiptap::Overlay::FormComponentTest::NestedCard",
        "version" => 1,
        "data" => data,
      }
    end
end
