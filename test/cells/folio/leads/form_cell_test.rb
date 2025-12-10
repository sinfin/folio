# frozen_string_literal: true

require "test_helper"

class Folio::Leads::FormCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/leads/form").(:show)
    assert html.has_css?("form")

    html = cell("folio/leads/form",
                build(:folio_lead, email: "a")).(:show)
    assert html.has_css?("form")
  end

  test "shows success message" do
    html = cell("folio/leads/form", create(:folio_lead)).(:show)
    assert html.has_css?(".f-leads-form--submitted")
  end

  test "shows note from option" do
    html = cell("folio/leads/form", nil, note: "foo").(:show)
    # Find textarea that is NOT inside recaptcha div
    textarea = html.all("textarea").reject { |t| t[:name] == "g-recaptcha-response" }.first
    assert_equal "foo", textarea.value
  end
end
