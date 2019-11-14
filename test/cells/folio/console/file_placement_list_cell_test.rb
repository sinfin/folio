# frozen_string_literal: true

require 'test_helper'

class Folio::Console::FilePlacementListCellTest < Folio::Console::CellTest
  test 'hide for none' do
    html = cell('folio/console/file_placement_list', create(:folio_page)).(:show)
    assert_not html.has_css?('h2')
  end

  test 'show' do
    placement = create(:folio_document_placement)
    page = placement.placement
    html = cell('folio/console/file_placement_list', page).(:show)
    assert html.has_css?('h2')
  end
end
