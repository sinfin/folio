# frozen_string_literal: true

require 'test_helper'

class Folio::Console::DestroyButtonCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/destroy_button', create(:folio_page)).(:show)
    assert html.has_css?('.f-c-destroy-button')
  end
end
