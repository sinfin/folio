# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Layout::SidebarCellTest < Folio::Console::CellTest
  test 'show' do
    create(:folio_site)
    html = cell('folio/console/layout/sidebar').(:show)
    assert html.has_css?('.f-c-layout-sidebar')
  end
end
