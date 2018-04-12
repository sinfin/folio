# frozen_string_literal: true

require 'test_helper'

class Folio::Console::BooleanToggleCellTest < Folio::Console::CellTest
  test 'show' do
    node = create(:folio_node, published: true, featured: true)
    html = cell('folio/console/boolean_toggle', node, as: :node).(:show)
    assert html
  end
end
