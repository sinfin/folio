# frozen_string_literal: true

require 'test_helper'

class Console::ReactImageSelectCellTest < Cell::TestCase
  test 'show' do
    html = cell('react_image_select').(:show)
    assert html.match /<p>/
  end
end
