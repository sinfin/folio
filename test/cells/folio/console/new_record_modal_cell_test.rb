# frozen_string_literal: true

require "test_helper"

class Folio::Console::NewRecordModalCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/new_record_modal", Folio::Page).(:show)
    assert html.has_css?(".f-c-new-record-modal")

    html = cell("folio/console/new_record_modal", Folio::Page).(:toggle)
    assert html.has_css?(".f-c-new-record-modal__toggle")
  end
end
