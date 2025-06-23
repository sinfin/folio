# frozen_string_literal: true

require "test_helper"

class Dummy::Tiptap::Node::CardComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Tiptap::Node::CardComponent.new(model:))

    assert_selector(".d-tiptap-node-card")
  end
end
