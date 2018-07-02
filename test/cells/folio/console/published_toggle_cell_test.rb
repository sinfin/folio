# frozen_string_literal: true

require 'test_helper'

class Folio::Console::PublishedToggleCellTest < Folio::Console::CellTest
  test 'show' do
    node = create(:folio_node, published: true)
    html = cell('folio/console/published_toggle', node, as: :node).(:show)
    assert html.find_css('input').attr('checked')

    node = create(:folio_node, published: false)
    html = cell('folio/console/published_toggle', node, as: :node).(:show)
    assert_not html.find_css('input').attr('checked')
  end
end
