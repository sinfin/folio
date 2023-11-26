# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuToolbarComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::MenuToolbarComponent.new(model:))

    assert_selector(".d-ui-menu-toolbar")
  end
end
