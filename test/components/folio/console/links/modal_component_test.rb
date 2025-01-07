# frozen_string_literal: true

require "test_helper"

class Folio::Console::Links::ModalComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Links::ModalComponent.new)
    assert_selector(".f-c-links-modal")
  end
end
