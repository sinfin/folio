# frozen_string_literal: true

require "test_helper"

class Folio::ChartCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/chart", nil).(:show)
    assert html.has_css?(".folio--folio-chart")
  end
end
