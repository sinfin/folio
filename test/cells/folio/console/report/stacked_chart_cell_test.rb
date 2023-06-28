# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::StackedChartCellTest < Folio::Console::CellTest
  test "show" do
    model = [
      {
        label: "Aktivní",
        color: :blue,
        values: [1, 2],
      },
      {
        label: "Noví",
        color: :green,
        values: [3, 4],
      },
    ]

    opts = {
      chart_data: {
        date_spans: [2.days.ago, 1.day.ago],
        date_labels: %w[foo bar],
      }
    }

    html = cell("folio/console/report/stacked_chart", model, opts).(:show)
    assert html.has_css?(".f-c-report-stacked-chart")
  end
end
