# frozen_string_literal: true

require "test_helper"

class Folio::Console::FormModalComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::FormModalComponent.new)

    assert_selector(".f-c-form-modal")
  end
end
