# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Atoms::Previews::LabelCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/atoms/previews/label', nil).(:show)
    assert_not html.has_css?('.f-c-atoms-previews__label')

    html = cell('folio/console/atoms/previews/label', 'foo').(:show)
    assert html.has_css?('.f-c-atoms-previews__label')
  end
end
