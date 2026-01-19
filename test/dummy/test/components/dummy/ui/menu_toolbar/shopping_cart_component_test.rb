# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::MenuToolbar::ShoppingCartComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::MenuToolbar::ShoppingCartComponent.new)

    assert_selector(".d-ui-menu-toolbar-shopping-cart")
  end
end
