# frozen_string_literal: true

require "test_helper"

class Folio::Console::Layout::AuditedBarCellTest < Folio::Console::CellTest
  test "show" do
    page = create(:folio_page)

    html = cell("folio/console/layout/audited_bar", nil).(:show)
    assert_not html.has_css?(".f-c-layout-audited-bar")

    html = cell("folio/console/layout/audited_bar", page.revisions.last).(:show)
    assert html.has_css?(".f-c-layout-audited-bar")
  end
end
