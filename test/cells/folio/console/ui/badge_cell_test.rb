# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::BadgeCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/ui/badge", nil).(:show)
    assert html.has_css?(".f-c-ui-badge")
  end
end
