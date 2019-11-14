# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Show::HeaderCellTest < Folio::Console::CellTest
  test 'show' do
    page = create(:folio_page, title: 'foo')
    html = cell('folio/console/show/header', page).(:show)
    assert html.has_css?('.f-c-show-header')
    assert_equal 'foo', html.find_css('h1').text
  end
end
