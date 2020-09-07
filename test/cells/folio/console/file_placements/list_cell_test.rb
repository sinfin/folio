# frozen_string_literal: true

require "test_helper"

class Folio::Console::FilePlacements::ListCellTest < Folio::Console::CellTest
  test "show" do
    model = create_list(:folio_cover_placement, 1)
    html = cell("folio/console/file_placements/list", model).(:show)
    assert html.has_css?(".f-c-file-list__img")
  end
end
