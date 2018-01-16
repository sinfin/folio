# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Index::HeaderCellTest < Cell::TestCase
  test 'show' do
    html = cell('folio/console/index/header').(:show)
    assert html.has_css?('.folio-console-by-query')
  end
end
