# frozen_string_literal: true

require "test_helper"

class Folio::Console::Aasm::FormModalComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Aasm::FormModalComponent.new)

    assert_selector(".f-c-aasm-form-modal")
  end
end
