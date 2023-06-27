# frozen_string_literal: true

require "test_helper"

class Folio::Console::Reports::IndexCellTest < Folio::Console::CellTest
  test "show" do
    model = {}
    html = cell("folio/console/reports/index", model, block: Proc.new { title "hello" }).(:show)
    assert html.has_css?(".f-c-reports-index")
  end
end
