# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::StylesComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Tiptap::StylesComponent.new(model:))

    assert_selector(".f-tiptap-styles")
  end
end
