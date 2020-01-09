# frozen_string_literal: true

require 'test_helper'

class Folio::Console::FileListCellTest < Folio::Console::CellTest
  test 'no files' do
    html = cell('folio/console/file_list', []).(:show)
    assert_equal '', html.native.inner_html
  end

  test 'danger flash' do
    html = cell('folio/console/file_list', create_list(:folio_image, 1)).(:show)
    assert html.has_css?('.f-c-file-list__img-wrap')
  end
end
