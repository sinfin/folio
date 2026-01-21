# frozen_string_literal: true

require "test_helper"

class Folio::Console::ConsoleNotes::CatalogueTooltipComponentTest < Folio::Console::ComponentTest
  test "show" do
    with_controller_class(Folio::Console::Api::ConsoleNotesController) do
      with_request_url "/console" do
        note = create(:folio_console_note, target: create(:folio_page))
        record = OpenStruct.new(console_notes: [note])

        render_inline(Folio::Console::ConsoleNotes::CatalogueTooltipComponent.new(record: record))
        assert_selector(".f-c-console-notes-catalogue-tooltip--some-open")
        assert_no_selector(".f-c-console-notes-catalogue-tooltip--only-closed")

        note.update!(closed_at: Time.current)

        render_inline(Folio::Console::ConsoleNotes::CatalogueTooltipComponent.new(record: record))
        assert_no_selector(".f-c-console-notes-catalogue-tooltip--some-open")
        assert_selector(".f-c-console-notes-catalogue-tooltip--only-closed")
      end
    end
  end
end
