# frozen_string_literal: true

require "test_helper"

class Folio::Console::Atoms::Previews::BrokenPreviewCellTest < Folio::Console::CellTest
  test "show" do
    error = StandardError.new("Some error")
    html = cell("folio/console/atoms/previews/broken_preview", error:).(:show)
    assert html.has_css?(".f-c-atoms-previews-broken-preview")
  end
end
