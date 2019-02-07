# frozen_string_literal: true

require 'test_helper'

class Folio::Console::PublishedToggleCellTest < Folio::Console::CellTest
  test 'show' do
    page = create(:folio_page, published: true)
    html = cell('folio/console/published_toggle', page, as: :page).(:show)
    assert html.find_css('input').attr('checked')

    page = create(:folio_page, published: false)
    html = cell('folio/console/published_toggle', page, as: :page).(:show)
    assert_not html.find_css('input').attr('checked')
  end
end
