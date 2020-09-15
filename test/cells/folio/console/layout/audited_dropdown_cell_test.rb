# frozen_string_literal: true

require "test_helper"

class Folio::Console::Layout::AuditedDropdownCellTest < Folio::Console::CellTest
  test "show" do
    page = create(:folio_page)

    html = cell("folio/console/layout/audited_dropdown",
                page.revisions.reverse).(:show)
    assert_not html.has_css?(".f-c-layout-audited-dropdown")

    page.update!(title: "foo")
    page.update!(title: "bar")

    html = cell("folio/console/layout/audited_dropdown",
                page.revisions.reverse).(:show)
    assert html.has_css?(".f-c-layout-audited-dropdown")
  end
end
