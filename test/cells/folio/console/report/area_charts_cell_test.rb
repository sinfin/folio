# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::AreaChartsCellTest < Folio::Console::CellTest
  test "show" do
    model = [
      {
        title: "Předplatitelé",
        text: "Celkem",
        values: Array.new(2) { rand(10000) },
      },
      {
        title: "Shlédnutí a přehrání",
        text: "Celkem na webu",
        values: Array.new(2) { rand(10000) },
      },
      {
        title: "Doba přehrávání",
        text: "Průměrná doba přehrávání na webu",
        values: Array.new(2) { rand(20) },
        unit: "min",
      },
    ]

    opts = { report: Folio::Report.new(controller:, group_by: "day", date_time_from: 2.days.ago, date_time_to: 1.day.ago) }

    html = cell("folio/console/report/area_charts", model, opts).(:show)
    assert html.has_css?(".f-c-report-area-charts")
  end
end
