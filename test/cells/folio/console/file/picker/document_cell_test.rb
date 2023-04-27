# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::Picker::DocumentCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/file/picker/document", nil).(:show)
    assert html.has_css?(".f-c-file-picker-document")
  end
end
