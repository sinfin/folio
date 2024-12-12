# frozen_string_literal: true

require "test_helper"

class Folio::Atoms::FlashTriggerForBrokenComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Atoms::FlashTriggerForBrokenComponent.new(model:))

    assert_selector(".d-atoms-flash-trigger-for-broken")
  end
end
