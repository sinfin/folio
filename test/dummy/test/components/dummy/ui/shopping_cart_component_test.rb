# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ShoppingCartComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::ShoppingCartComponent.new(model:))

    assert_selector(".d-ui-shopping-cart")
  end
end
