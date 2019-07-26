# frozen_string_literal: true

require 'test_helper'

class Folio::Console::AtomsFormHeaderCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/atoms_form_header', create(:folio_page)).(:show)
    assert html.has_css?('.f-c-atoms-form-header__button--settings')
    assert html.has_css?('.f-c-atoms-form-header__button--locale')
  end
end
