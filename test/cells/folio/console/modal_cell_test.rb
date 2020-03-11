# frozen_string_literal: true

require 'test_helper'

class Folio::ConsoleModalCellTest < Cell::TestCase
  test 'show' do
    model = {
      class: 'foo',
      body: 'bar'
    }
    html = cell('folio/console/modal', model).(:show)
    assert html.has_css?('.f-c-modal')
    assert html.has_css?('.foo')
    assert_equal 'barclose', html.text
  end
end
