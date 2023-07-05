# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::AlertCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/ui/alert", nil).(:show)
    assert html.has_css?(".f-c-ui-alert")
  end
end
