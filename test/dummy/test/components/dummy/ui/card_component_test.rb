# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::CardComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::CardComponent.new(model:))

    assert_selector(".d-ui-card")
  end
end
