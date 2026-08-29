# frozen_string_literal: true

require "test_helper"

class Dummy::Tiptap::Node::CardGroupComponentTest < Folio::Tiptap::NodeComponentTest
  def test_render
    node = Dummy::Tiptap::Node::CardGroup.new(
      title: "Card group",
      cards: [
        {
          "type" => "Dummy::Tiptap::Node::CardGroup::Card",
          "version" => 1,
          "data" => {
            "title" => "Nested card",
          },
        },
      ],
    )

    render_inline(Dummy::Tiptap::Node::CardGroupComponent.new(node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card-group")
    assert_selector(".d-tiptap-node-card-group__card")
    assert_text("Card group")
    assert_text("Nested card")
  end
end
