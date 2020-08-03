# frozen_string_literal: true

require 'test_helper'

class Folio::Console::CatalogueCellTest < Folio::Console::CellTest
  test 'show' do
    model = { records: create_list(:folio_page, 1), block: Proc.new { edit_link(:title) } }
    html = cell('folio/console/catalogue', model).(:show)
    assert html.has_css?('.f-c-catalogue')
    assert html.has_css?('.f-c-catalogue__header-cell')
    assert html.has_css?('.f-c-catalogue__header-cell--edit_link')
  end
end
