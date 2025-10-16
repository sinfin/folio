# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ClearButtonComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::ClearButtonComponent.new)

    assert_selector(".f-c-ui-clear-button")
  end
end
