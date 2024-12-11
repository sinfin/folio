# frozen_string_literal: true

require "test_helper"

class Folio::Console::Atoms::Previews::BrokenPreviewCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/atoms/previews/broken_preview", nil).(:show)
    assert html.has_css?(".f-c-atoms-previews-broken-preview")
  end
end
