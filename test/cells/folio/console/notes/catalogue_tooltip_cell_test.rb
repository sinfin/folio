# frozen_string_literal: true

require "test_helper"

class Folio::Console::Notes::CatalogueTooltipCellTest < Folio::Console::CellTest
  test "show" do
    note = create(:folio_console_note, target: create(:folio_page))
    model = OpenStruct.new(console_notes: [note])

    html = cell("folio/console/notes/catalogue_tooltip", model).(:show)
    assert html.has_css?(".f-c-notes-catalogue-tooltip")

    note.update!(closed_at: Time.current)

    html = cell("folio/console/notes/catalogue_tooltip", model).(:show)
    assert_not html.has_css?(".f-c-notes-catalogue-tooltip")
  end
end
