# frozen_string_literal: true

require 'test_helper'

class Folio::Console::BooleanToggleCellTest < Folio::Console::CellTest
  test 'show' do
    page = create(:folio_page, published: true, featured: true)
    html = cell('folio/console/boolean_toggle', page, as: :page).(:show)
    assert html
  end
end
