# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Layout::Sidebar::SearchCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/layout/sidebar/search', nil).(:show)
    assert html.has_css?('.f-c-layout-sidebar-search')
  end
end
