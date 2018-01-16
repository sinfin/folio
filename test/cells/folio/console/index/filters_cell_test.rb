# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Index::FiltersCellTest < Cell::TestCase
  test 'show' do
    html = cell('folio/console/index/filters', [:by_type]).(:show)

    assert_equal 1,
                 html.find_css('input[type="hidden"][name="by_query"]').length
    assert_equal 1,
                 html.find_css('select[name="by_type"]').length
  end
end
