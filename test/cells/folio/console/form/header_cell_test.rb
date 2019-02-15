# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Form::HeaderCellTest < Cell::TestCase
  test 'show' do
    page = create(:folio_page, title: 'foo')
    html = cell('folio/console/form/header', page).(:show)
    assert html.has_css?('.f-c-form-header')
    assert_equal 'foo', html.find_css('h1').text
  end
end
