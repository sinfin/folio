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

    opts = { report: Folio::Report.new(controller:, group_by: "day", date_time_from: 2.days.ago, date_time_to: 1.day.ago) }

    html = cell("folio/console/report/stacked_chart", model, opts).(:show)
    assert html.has_css?(".f-c-report-stacked-chart")
  end
end
