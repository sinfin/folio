# frozen_string_literal: true

require "test_helper"

class Folio::Console::Authentications::ListCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/authentications/list", nil).(:show)
    assert html.has_css?(".f-c-authentications-list")
  end
end
