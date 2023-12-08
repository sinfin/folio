# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuToolbar::ShoppingCartComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::MenuToolbar::ShoppingCartComponent.new)

    assert_selector(".d-ui-menu-toolbar-shopping-cart")
  end
end
