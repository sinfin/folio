# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::Picker::ThumbCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/file/picker/thumb", nil).(:show)
    assert html.has_css?(".f-c-file-picker-thumb")
  end
end
