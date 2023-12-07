# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuToolbar::ToolbarComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::MenuToolbar::ToolbarComponent.new(model:))

    assert_selector(".d-ui-menu-toolbar-toolbar")
  end
end
