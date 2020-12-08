# frozen_string_literal: true

require "test_helper"

class Folio::Console::ClipboardCopyCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/clipboard_copy", "content").(:show)
    assert html.has_css?(".f-c-clipboard-copy")

    html = cell("folio/console/clipboard_copy", nil).(:show)
    assert_not html.has_css?(".f-c-clipboard-copy")
  end
end
