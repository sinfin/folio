# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::OverlayComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Tiptap::OverlayComponent.new)

    assert_selector(".f-c-tiptap-overlay")
  end
end
