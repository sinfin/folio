# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Atoms::SettingsHeaderCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/atoms/settings_header', nil).(:show)
    assert html.has_css?('.f-c-atoms-settings-header')
  end
end
