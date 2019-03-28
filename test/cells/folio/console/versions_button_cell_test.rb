# frozen_string_literal: true

require 'test_helper'

class Folio::Console::VersionsButtonCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/versions_button', create(:folio_page)).(:show)
    assert html.has_css?('.f-c-versions-btn')
  end
end
