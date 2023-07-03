# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::BoxCellTest < Folio::Console::CellTest
  test "show" do
    model = {
      title: "Prodaná předplatná",
      stats: {
        "Počet nákupů" => 253,
        "Počet předplatitelů" => 120,
        "Z toho prémiových předplatitelů" => 12,
      },
      total_price: 450000
    }

    html = cell("folio/console/report/box", model).(:show)
    assert html.has_css?(".f-c-report-box")
  end
end
