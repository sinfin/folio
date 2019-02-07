# frozen_string_literal: true

require 'test_helper'

class Folio::Console::FeaturedToggleCellTest < Folio::Console::CellTest
  test 'show' do
    page = create(:folio_page, featured: true)
    html = cell('folio/console/featured_toggle', page, as: :page).(:show)
    assert html.find_css('input').attr('checked')

    page = create(:folio_page, featured: false)
    html = cell('folio/console/featured_toggle', page, as: :page).(:show)
    assert_not html.find_css('input').attr('checked')
  end
end
