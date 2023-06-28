# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::StackedChartCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/report/stacked_chart", nil).(:show)
    assert html.has_css?(".f-c-report-stacked-chart")
  end
end
