# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::FormComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new)

    assert_selector(".f-c-tiptap-overlay-form")
  end
end
