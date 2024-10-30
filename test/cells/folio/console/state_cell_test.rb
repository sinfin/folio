# frozen_string_literal: true

require "test_helper"

class Folio::Console::StateCellTest < Folio::Console::CellTest
  test "show displays no events without current user" do
    lead = create(:folio_lead)

    html = cell("folio/console/state", lead).(:show)

    state_div = html.find(".f-c-state", text: "K vyřízení")
    assert state_div.present?
    # no current user => no events
    assert_not state_div.has_css?(".dropdown-item")
  end

  test "show displays no events, if current user do not have allowed actions" do
    lead = create(:folio_lead)
    assert_equal [:to_pending, :to_handled], lead.permitted_event_names
    Folio::Current.user = create(:folio_site_user_link, roles: [], site: lead.site).user

    html = cell("folio/console/state", lead).(:show)

    state_div = html.find(".f-c-state", text: "K vyřízení")
    assert state_div.present?
    # no admin user => no events
    assert_not state_div.has_css?(".dropdown-item")
  end

  test "administrator can see allowed events" do
    lead = create(:folio_lead)
    assert_equal [:to_pending, :to_handled], lead.permitted_event_names
    Folio::Current.user = create(:folio_site_user_link, roles: [:administrator], site: lead.site).user

    html = cell("folio/console/state", lead).(:show)

    state_div = html.find(".f-c-state", text: "K vyřízení")
    assert state_div.present?

    assert state_div.find(".dropdown-item", text: "Označit jako vyřizovaný")["data-url"].include?("aasm_event=to_pending")
    assert state_div.find(".dropdown-item", text: "Vyřídit")["data-url"].include?("aasm_event=to_handled")

    lead.to_handled!

    html = cell("folio/console/state", lead).(:show)
    state_div = html.find(".f-c-state", text: "Vyřízeno")
    assert state_div.find(".dropdown-item", text: "Označit jako vyřizovaný")["data-url"].include?("aasm_event=to_pending")
    assert state_div.find(".dropdown-item", text: "Označit jako nevyřízený")["data-url"].include?("aasm_event=to_submitted")
  end
end
