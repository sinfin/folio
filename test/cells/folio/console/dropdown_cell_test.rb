# frozen_string_literal: true

require 'test_helper'

class Folio::Console::DropdownCellTest < Cell::TestCase
  test 'show' do
    links = [
      { url: '/foo', title: 'foo' },
      { url: '/bar', title: 'bar' },
    ]
    html = cell('folio/console/dropdown', title: 'test', links: links).(:show)

    assert_equal 'test', html.find_css('button').inner_html.strip
    assert_equal 2, html.find_all('a.dropdown-item').size
  end
end
