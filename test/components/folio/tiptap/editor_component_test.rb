# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::EditorComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Tiptap::EditorComponent.new(model:))

    assert_selector(".f-tiptap-editor")
  end
end
