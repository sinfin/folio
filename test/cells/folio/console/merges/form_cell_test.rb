# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Merges::FormCellTest < Folio::Console::CellTest
  test 'show' do
    original = create(:folio_page)
    duplicate = create(:folio_page)
    merger = Folio::Page::Merger.new(original, duplicate)
    html = cell('folio/console/merges/form', merger).(:show)
    assert html.has_css?('.f-c-merges-form')
  end
end
