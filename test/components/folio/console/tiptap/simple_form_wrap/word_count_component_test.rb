# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::SimpleFormWrap::WordCountComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Tiptap::SimpleFormWrap::WordCountComponent.new)
    assert_selector(".f-c-tiptap-simple-form-wrap-word-count")
  end
end
