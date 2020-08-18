# frozen_string_literal: true

require "test_helper"

class Folio::Console::Index::ActionsCellTest < Folio::Console::CellTest
  test "show" do
    page = create(:folio_page)
    html = cell("folio/console/index/actions", page).(:show)
    assert html.has_css?(".btn-secondary")
    assert html.has_css?(".btn-danger")
  end
end
