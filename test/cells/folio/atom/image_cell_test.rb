# frozen_string_literal: true

require 'test_helper'

class Folio::Atom::ImageCellTest < Cell::TestCase
  test 'show' do
    atom = create(:folio_atom, content: 'foo')
    html = cell('folio/atom/image', atom).(:show)
    assert_equal 'foo', html.find_css('p').text
  end
end
