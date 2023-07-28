# frozen_string_literal: true

require "test_helper"

class Folio::Console::ReportCellTest < Folio::Console::CellTest
  test "show" do
    model = {}
    html = cell("folio/console/report", model, block: Proc.new { title "hello" }).(:show)
    assert html.has_css?(".f-c-report")
  end
end
