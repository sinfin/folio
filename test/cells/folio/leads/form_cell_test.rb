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
    assert_equal "foo", html.find("textarea").value
  end

  test "shows attachment from option" do
    html = cell("folio/leads/form", nil,
                                    layout: { cols: [%i[attachment]] },
                                    attachment_klass: Folio::SessionAttachment::Image).(:show)

    assert html.has_css?(".f-dropzone")
  end
end
