# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Index::TabsCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/index/tabs', nil).(:show)
    assert_not html.has_css?('.f-c-index-tabs')

    tabs = [{ href: '#foo', label: 'foo' }]
    html = cell('folio/console/index/tabs', tabs).(:show)
    assert html.has_css?('.f-c-index-tabs')
  end
end
