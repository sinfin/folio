# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::AreaChartCellTest < Folio::Console::CellTest
  test "show" do
    model = {
      title: "Předplatitelé",
      text: "Celkem",
      values: Array.new(2) { rand(10000) },
    }

    opts = { report: Folio::Report.new(controller:, group_by: "day", date_time_from: 2.days.ago, date_time_to: 1.day.ago) }

    html = cell("folio/console/report/area_chart", model, opts).(:show)
    assert html.has_css?(".f-c-report-area-chart")
  end
end
