# frozen_string_literal: true

require 'test_helper'

class Folio::Console::FeaturedToggleCellTest < Folio::Console::CellTest
  test 'show' do
    node = create(:folio_node, featured: true)
    html = cell('folio/console/featured_toggle', node, as: :node).(:show)
    assert html.find_css('input').attr('checked')

    node = create(:folio_node, featured: false)
    html = cell('folio/console/featured_toggle', node, as: :node).(:show)
    refute html.find_css('input').attr('checked')
  end
end
