# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponentTest < Folio::Console::ComponentTest
  def test_render
    attribute_names = %w[tiptap_content_cs tiptap_content_en]
    locales = %i[cs en]
    render_inline(Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponent.new(attribute_names: attribute_names, locales: locales))

    assert_selector(".f-c-tiptap-simple-form-wrap-locale-switch")
  end
end
