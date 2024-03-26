# frozen_string_literal: true

require "test_helper"

class Folio::Console::Index::NewButtonCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/index/new_button", klass: Folio::Page).(:show)
    assert html.has_css?(".f-c-index-new-button")
  end
end
