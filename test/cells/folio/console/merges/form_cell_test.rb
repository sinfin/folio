# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Merges::FormCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/merges/form', nil).(:show)
    assert html.has_css?('.f-c-merges-form')
  end
end
