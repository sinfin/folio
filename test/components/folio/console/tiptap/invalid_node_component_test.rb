# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::InvalidNodeComponentTest < Folio::Console::ComponentTest
  def test_render
    node = Dummy::Tiptap::Node::Card.new
    assert_not node.valid?

    render_inline(Folio::Console::Tiptap::InvalidNodeComponent.new(node:))

    assert_selector(".f-c-tiptap-invalid-node")
  end
end
