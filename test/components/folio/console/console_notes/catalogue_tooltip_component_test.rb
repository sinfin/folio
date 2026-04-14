# frozen_string_literal: true

require "test_helper"

class Folio::Console::ConsoleNotes::CatalogueTooltipComponentTest < Folio::Console::ComponentTest
  def vc_test_controller_class
    Folio::Console::PagesController
  end

  test "render" do
    note = create(:folio_console_note, target: create(:folio_page))
    model = OpenStruct.new(console_notes: [note])

    render_inline(Folio::Console::ConsoleNotes::CatalogueTooltipComponent.new(record: model))

    assert_selector(".f-c-console-notes-catalogue-tooltip[data-controller='f-c-console-notes-catalogue-tooltip']")
    assert_includes rendered_content, "f-c-console-notes-catalogue-tooltip#onNoteChange"
    assert_selector(".f-c-console-notes-catalogue-tooltip--some-open")
    assert_no_selector(".f-c-console-notes-catalogue-tooltip--only-closed")

    note.update!(closed_at: Time.current)

    render_inline(Folio::Console::ConsoleNotes::CatalogueTooltipComponent.new(record: model))

    assert_no_selector(".f-c-console-notes-catalogue-tooltip--some-open")
    assert_selector(".f-c-console-notes-catalogue-tooltip--only-closed")
  end
end
