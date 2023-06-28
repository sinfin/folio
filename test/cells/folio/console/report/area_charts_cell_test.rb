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

    html = cell("folio/console/report/area_charts", model).(:show)
    assert html.has_css?(".f-c-report-area-charts")
  end
end
