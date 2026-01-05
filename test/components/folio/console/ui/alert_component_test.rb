# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::AlertComponentTest < Folio::Console::ComponentTest
  def test_render
    "hello"

    render_inline(Folio::Console::Ui::AlertComponent.new(variant: "danger") { "foo" })

    assert_selector(".f-c-ui-alert")
  end
end
