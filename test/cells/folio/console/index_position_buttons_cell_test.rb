# frozen_string_literal: true

require 'test_helper'

class Folio::Console::IndexPositionButtonsCellTest < Folio::Console::CellTest
  test 'show' do
    page = create(:folio_page)
    html = cell('folio/console/index_position_buttons', page, as: :pages).(:show)
    assert html.has_css?('.btn-group')
  end
end
