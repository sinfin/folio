# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Form::HeaderCellTest < Cell::TestCase
  test 'show' do
    node = create(:folio_node, title: 'foo')
    html = cell('folio/console/form/header', node).(:show)
    assert html.has_css?('.folio-console-form-header')
    assert_equal 'foo', html.find_css('h1').text
  end
end
