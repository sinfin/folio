# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuToolbar::ShoppedItemsCountComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::MenuToolbar::ShoppedItemsCountComponent.new)

    assert_selector(".d-ui-menu-toolbar-shopped-items-count")
  end
end
