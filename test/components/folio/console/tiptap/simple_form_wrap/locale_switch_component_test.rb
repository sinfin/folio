# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponentTest < Folio::Console::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponent.new(model:))

    assert_selector(".f-c-tiptap-simple-form-wrap-locale-switch")
  end
end
