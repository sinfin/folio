# frozen_string_literal: true

require "test_helper"

class Folio::Console::StateCellTest < Folio::Console::CellTest
  test "show" do
    lead = create(:folio_lead)

    html = cell("folio/console/state", lead).(:show)
    assert_match("aasm_event=handle", html.find(".dropdown-item").native["data-url"])

    lead.handle!

    html = cell("folio/console/state", lead).(:show)
    assert_match("aasm_event=unhandle", html.find(".dropdown-item").native["data-url"])
  end
end
