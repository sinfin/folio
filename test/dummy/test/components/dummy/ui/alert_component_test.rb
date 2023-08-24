# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::AlertComponentTest < Folio::ComponentTest
  def test_render
    message = "hello"

    render_inline(Dummy::Ui::AlertComponent.new(message:))

    assert_selector(".d-ui-alert")
  end
end
