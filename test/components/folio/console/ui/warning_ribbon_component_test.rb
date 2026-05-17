# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::WarningRibbonComponentTest < Folio::Console::ComponentTest
  test "show" do
    render_inline(Folio::Console::Ui::WarningRibbonComponent.new(text: "foo"))
    assert_selector(".f-c-ui-warning-ribbon")
  end
end
