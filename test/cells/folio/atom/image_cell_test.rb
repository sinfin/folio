# frozen_string_literal: true

require 'test_helper'

class Folio::Atom::ImageCellTest < Cell::TestCase
  test 'show' do
    atom = create(:folio_image_atom)
    html = cell('folio/atom/image', atom).(:show)
    assert html.has_css?('img')
  end
end
