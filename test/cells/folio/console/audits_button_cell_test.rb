# frozen_string_literal: true

require 'test_helper'

class Folio::Console::AuditsButtonCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/audits_button', create(:folio_page)).(:show)
    assert html.has_css?('.f-c-audits-btn')
  end
end
