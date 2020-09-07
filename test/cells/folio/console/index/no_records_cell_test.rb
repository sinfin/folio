# frozen_string_literal: true

require "test_helper"

class Folio::Console::Index::NoRecordsCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/index/no_records", Folio::Page).(:show)
    assert html.has_css?(".f-c-index-no-records")
  end
end
