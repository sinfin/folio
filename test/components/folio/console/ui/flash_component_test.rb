# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::FlashComponentTest < Folio::Console::ComponentTest
  def test_render
    flash = ActionDispatch::Flash::FlashHash.new
    flash[:error] = "foo"

    render_inline(Folio::Console::Ui::FlashComponent.new(flash:))

    assert_selector(".f-c-ui-flash")
    assert_selector(".f-c-ui-flash .f-c-ui-alert")
  end

  def test_blank
    flash = nil

    render_inline(Folio::Console::Ui::FlashComponent.new(flash:))

    assert_selector(".f-c-ui-flash", visible: false)
    assert_no_selector(".f-c-ui-flash .f-c-ui-alert")
  end
end
