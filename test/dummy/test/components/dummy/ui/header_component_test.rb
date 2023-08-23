# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::HeaderComponent.new(model:))

    assert_selector(".d-ui-header")
  end
end
