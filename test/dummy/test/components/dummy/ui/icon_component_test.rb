# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::IconComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::IconComponent.new(model:))

    assert_selector(".d-ui-icon")
  end
end
