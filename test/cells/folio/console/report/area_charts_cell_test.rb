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

    opts = {
      graphs_data: {
        date_spans: [2.days.ago, 1.day.ago],
        date_labels: %w[foo bar],
      }
    }

    html = cell("folio/console/report/area_charts", model, opts).(:show)
    assert html.has_css?(".f-c-report-area-charts")
  end
end
