# frozen_string_literal: true

require 'test_helper'

class Folio::Console::IndexPositionButtonsCellTest < Folio::Console::CellTest
  test 'show' do
    node = create(:folio_node)
    html = cell('folio/console/index_position_buttons', node, as: :nodes).(:show)
    assert html.has_css?('.btn-group')
  end
end
