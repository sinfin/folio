# frozen_string_literal: true

require "test_helper"

class Folio::Console::Layout::Sidebar::TitleCellTest < Folio::Console::CellTest
  test "show" do
    create_and_host_site
    html = cell("folio/console/layout/sidebar/title", nil).(:show)
    assert html.has_css?(".f-c-layout-sidebar-title")
  end
end
