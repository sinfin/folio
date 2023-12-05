# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::Input::WithIconComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::Input::WithIconComponent.new(model:))

    assert_selector(".d-ui-input-with-icon")
  end
end
