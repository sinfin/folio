# frozen_string_literal: true

require 'test_helper'

class Folio::Console::AtomPreviewsCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/atom_previews', nil).(:show)
    assert html.has_css?('.f-c-atom-preview')
  end
end
