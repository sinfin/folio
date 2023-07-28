# frozen_string_literal: true

require "test_helper"

class Folio::ChartCellTest < Cell::TestCase
  test "show" do
    model = {
      data: {
        datasets: [{
          borderColor: "#4C84FD",
          backgroundColor: "#E4F0FC",
          fill: true,
          label: "Předplatitelé",
          data: [1, 2]
        }],
        labels: ["a", "b"]
      },
      type: :line,
      options: {
        layout: { autoPadding: false },
        scales: { x: { display: false }, y: { display: false } },
        plugins: { legend: { display: false } },
        elements: { point: { pointStyle: false } },
        animation: { duration: 0 }
      }
    }

    html = cell("folio/chart", model).(:show)
    assert html.has_css?(".f-chart")
  end
end
