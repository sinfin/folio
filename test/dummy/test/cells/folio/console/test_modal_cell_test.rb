# frozen_string_literal: true

require "test_helper"

class Folio::Console::TestModalCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/test_modal", nil).(:show)
    assert html.has_css?(".f-c-d-test-modal")
  end
end
