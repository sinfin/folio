# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ClearButtonComponentTest < Folio::Console::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Console::Ui::ClearButtonComponent.new(model:))

    assert_selector(".f-c-ui-clear-button")
  end
end
