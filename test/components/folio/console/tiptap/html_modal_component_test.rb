# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::HtmlModalComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Tiptap::HtmlModalComponent.new)

    assert_selector(".f-c-tiptap-html-modal")
  end
end
