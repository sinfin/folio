# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponent.new(base_field: :tiptap_content, locales: %i[cs en]))

    assert_selector(".f-c-tiptap-simple-form-wrap-locale-switch")
  end
end
