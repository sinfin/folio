# frozen_string_literal: true

require "test_helper"

class Folio::Console::Transportable::DropdownCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/transportable/dropdown", nil).(:show)
    assert html.has_css?(".f-c-transportable-dropdown")
  end
end
