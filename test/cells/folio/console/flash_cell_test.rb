# frozen_string_literal: true

require 'test_helper'

class Folio::Console::FlashCellTest < Folio::Console::CellTest
  test 'no flash' do
    html = cell('folio/console/flash', nil).(:show)
    assert_equal 0, html.find_css('.container').length
    assert_equal 0, html.find_css('.alert').length
  end

  test 'danger flash' do
    flash_hash = ActionDispatch::Flash::FlashHash.new
    flash_hash[:error] = 'foo'
    html = cell('folio/console/flash', flash_hash).(:show)
    assert html.has_css?('.alert-danger')
    assert html.has_css?('.fa-times-circle')
  end
end
