# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ShareComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::ShareComponent.new(model:))

    assert_selector(".d-ui-share")
  end
end
