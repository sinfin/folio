# frozen_string_literal: true

require 'test_helper'

class Folio::Console::DisabledDestroyButtonCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/disabled_destroy_button', 'foo').(:show)
    assert html.has_css?('.f-c-disabled-destroy-button')
  end
end
