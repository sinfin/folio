# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::DocumentsComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::DocumentsComponent.new(model:))

    assert_selector(".d-ui-documents")
  end
end
