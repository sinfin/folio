# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::TextStatsCellTest < Folio::Console::CellTest
  test "show" do
    model = [
      { label: "Celkový počet aktivních předplatných", value: 12111 },
      { label: "Verze A", value: 2111 },
    ]

    html = cell("folio/console/report/text_stats", model).(:show)
    assert html.has_css?(".f-c-report-text-stats")
  end
end
