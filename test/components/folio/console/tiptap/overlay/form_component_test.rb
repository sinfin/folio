# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::FormComponentTest < Folio::Console::ComponentTest
  def test_render
    node = Folio::Tiptap::Node::Card.new
    render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

    assert_selector(".f-c-tiptap-overlay-form")
  end
end
