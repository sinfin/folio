# frozen_string_literal: true

require 'test_helper'

class Folio::Console::CancelCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/cancel', nil).(:show)
    assert html.has_css?('.f-c-cancel')
  end
end
