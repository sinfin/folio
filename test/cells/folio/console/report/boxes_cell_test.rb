# frozen_string_literal: true

require "test_helper"

class Folio::Console::Report::BoxesCellTest < Folio::Console::CellTest
  test "show" do
    model = [
      {
        title: "Prodaná předplatná",
        stats: {
          "Počet nákupů" => 253,
          "Počet předplatitelů" => 120,
          "Z toho prémiových předplatitelů" => 12,
        },
        total_price: 450000
      },
      {
        title: "Ukončená předplatná",
        stats: {
          "Počet ukončení" => 253,
          "Počet předplatitelů" => 120,
        },
        total_price: -10000
      }
    ]

    html = cell("folio/console/report/boxes", model).(:show)
    assert html.has_css?(".f-c-report-box")
  end
end
