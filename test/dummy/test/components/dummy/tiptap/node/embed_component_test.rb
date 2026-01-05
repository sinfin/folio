# frozen_string_literal: true

require "test_helper"

class Dummy::Tiptap::Node::EmbedComponentTest < Folio::Tiptap::NodeComponentTest
  def test_render
    node = create_test_tiptap_node(Dummy::Tiptap::Node::Embed)

    render_inline(Dummy::Tiptap::Node::EmbedComponent.new(node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-embed")
  end
end
