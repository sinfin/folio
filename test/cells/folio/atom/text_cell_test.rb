# frozen_string_literal: true

require 'test_helper'

class Folio::Atom::TextCellTest < Cell::TestCase
  test 'show' do
    atom = create_atom(Folio::Atom::Text, content: '<p>foo</p>')
    html = cell('folio/atom/text', atom).(:show)
    assert_equal 'foo', html.find_css('p').text
  end
end
