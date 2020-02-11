# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Merges::Index::FooterCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/merges/index/footer', Folio::Page).(:show)
    assert html.has_css?('.f-c-merges-index-footer')
  end
end
