# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Atoms::Previews::PerexCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/atoms/previews/perex', nil).(:show)
    assert_not html.has_css?('.f-c-atoms-previews__perex')

    html = cell('folio/console/atoms/previews/perex', 'foo').(:show)
    assert html.has_css?('.f-c-atoms-previews__perex')
  end
end
