# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::WarningRibbonCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/ui/warning_ribbon", "foo").(:show)
    assert html.has_css?(".f-c-ui-warning-ribbon")
  end
end
