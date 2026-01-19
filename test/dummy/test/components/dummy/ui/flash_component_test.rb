# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::FlashComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::FlashComponent.new(flash: nil))
    assert_selector(".d-ui-flash")
    assert_no_selector(".d-ui-alert")

    flash_hash = ActionDispatch::Flash::FlashHash.new
    flash_hash[:error] = "foo"

    render_inline(Dummy::Ui::FlashComponent.new(flash: flash_hash))
    assert_selector(".d-ui-flash")
    assert_selector(".d-ui-alert")
  end
end
