# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::PreviewReloaderCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/file/preview_reloader", create(:folio_file_image)).(:show)
    assert html.has_css?(".f-c-file-preview-reloader", visible: false)
  end
end
