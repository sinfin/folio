# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::AreaChartCellTest < Folio::Console::CellTest
  test "show" do
    model = {
      title: "Předplatitelé",
      text: "Celkem",
      values: Array.new(2) { rand(10000) },
    }

    html = cell("folio/console/report/area_chart", model).(:show)
    assert html.has_css?(".f-c-report-area-chart")
  end
end
