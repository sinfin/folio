# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Index::FiltersCellTest < Cell::TestCase
  test 'show' do
    filter = {
      by_published: [
        ['All', nil],
        ['Published', 'published'],
        ['Unpublished', 'unpublished'],
      ]
    }
    html = cell('folio/console/index/filters', filter).(:show)

    assert_equal 1,
                 html.find_css('input[type="hidden"][name="by_query"]').length
    assert_equal 1,
                 html.find_css('select[name="by_published"]').length
  end
end
