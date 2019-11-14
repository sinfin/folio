# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Atoms::LocaleSwitchCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/atoms/locale_switch', nil).(:show)
    assert html.has_css?('.f-c-atoms-locale-switch')
  end
end
