# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Merges::Index::HeaderCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/merges/index/header', nil).(:show)
    assert html.has_css?('.f-c-merges-index-header')
  end
end
