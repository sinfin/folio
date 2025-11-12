# frozen_string_literal: true

require "test_helper"

class Dummy::Tiptap::Node::CardComponentTest < Folio::Tiptap::NodeComponentTest
  def test_render
    node = create_test_tiptap_node(Dummy::Tiptap::Node::Card, :title)

    render_inline(Dummy::Tiptap::Node::CardComponent.new(node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
  end
end
