# frozen_string_literal: true

require "test_helper"

class Folio::Console::StateCellTest < Folio::Console::CellTest
  test "show" do
    lead = create(:folio_lead)

    html = cell("folio/console/state", lead).(:show)
    assert_match("aasm_event=to_handled", html.find_all(".dropdown-item").last.native["data-url"])

    lead.to_handled!

    html = cell("folio/console/state", lead).(:show)
    assert_match("aasm_event=to_submitted", html.find_all(".dropdown-item")[0].native["data-url"])
  end
end
