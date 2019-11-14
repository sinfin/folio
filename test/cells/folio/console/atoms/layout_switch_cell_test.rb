# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Atoms::LayoutSwitchCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/atoms/layout_switch', nil).(:show)
    assert html.has_css?('.f-c-atoms-layout-switch')
  end
end
