# frozen_string_literal: true

require 'test_helper'

class Console::FooterCellTest < Cell::TestCase
  test 'show' do
    html = cell('footer').(:show)
    assert html.match /<p>/
  end
end
