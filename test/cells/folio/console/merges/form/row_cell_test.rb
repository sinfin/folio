# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Merges::Form::RowCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/merges/form/row', nil).(:show)
    assert html.has_css?('.f-c-merges-form-row')
  end
end
