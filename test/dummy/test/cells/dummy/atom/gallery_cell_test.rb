# frozen_string_literal: true

require 'test_helper'

class Dummy::Atom::GalleryCellTest < Cell::TestCase
  test 'show' do
    atom = create_atom(Dummy::Atom::Gallery)
    html = cell('dummy/atom/gallery', atom).(:show)
    assert html
  end
end
