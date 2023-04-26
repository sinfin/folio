# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::PickerCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/file/picker", nil).(:show)
    assert html.has_css?(".f-c-file-picker")
  end
end
