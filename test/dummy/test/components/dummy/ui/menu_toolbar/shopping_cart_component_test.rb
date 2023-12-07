# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuToolbar::ShoppingCartComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::MenuToolbar::ShoppingCartComponent.new(model:))

    assert_selector(".d-ui-menu-toolbar-shopping-cart")
  end
end
