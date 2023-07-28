# frozen_string_literal: true

require "test_helper"

class Folio::Console::Layout::HeaderCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/layout/header", {}).(:show)
    assert html.has_css?(".f-c-layout-header")
  end
end
