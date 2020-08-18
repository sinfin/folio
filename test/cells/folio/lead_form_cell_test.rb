# frozen_string_literal: true

require "test_helper"

class LeadFormCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/lead_form").(:show)
    assert html.has_css?("form")

    html = cell("folio/lead_form",
                build(:folio_lead, email: "a")).(:show)
    assert html.has_css?("form")
  end

  test "shows success message" do
    html = cell("folio/lead_form", create(:folio_lead)).(:show)
    assert html.has_css?(".folio-lead-form-submitted")
  end

  test "shows note from option" do
    html = cell("folio/lead_form", nil, note: "foo").(:show)
    assert_equal "foo", html.find("textarea").value
  end
end
