# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::AreaChartCellTest < Folio::Console::CellTest
  test "show" do
    model = {
      title: "Předplatitelé",
      text: "Celkem",
      values: Array.new(2) { rand(10000) },
    }

    opts = {
      chart_data: {
        date_spans: [2.days.ago, 1.day.ago],
        date_labels: %w[foo bar],
      }
    }

    html = cell("folio/console/report/area_chart", model, opts).(:show)
    assert html.has_css?(".f-c-report-area-chart")
  end
end
