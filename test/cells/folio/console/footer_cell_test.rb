# frozen_string_literal: true

require 'test_helper'

class Folio::Console::FooterCellTest < Folio::Console::CellTest
  test 'show' do
    site = create(:folio_site)

    html = cell('folio/console/footer', site).(:show)
    assert html.has_css?('.folio-console-footer')
  end
end
