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

  test "test layouts" do
    structure = [%i[email], %i[phone], %i[note]]

    layout = { rows: structure }
    html = cell("folio/leads/form", nil, layout:).(:show)
    assert_equal 3, html.find_css(".f-leads-form__col").size

    layout = { rows: structure, cols: structure }
    html = cell("folio/leads/form", nil, layout:).(:show)
    assert_equal 3, html.find_css(".f-leads-form__cell").size
  end

  test "test input options" do
    opts = {
      note: {
        label: "bar",
        input_html: { value: "foo" }
      }
    }

    html = cell("folio/leads/form", nil, input_opts: opts).(:show)
    assert_equal "foo", html.find("textarea").value

    html = cell("folio/leads/form", nil, input_opts: opts.to_json).(:show)
    assert_equal "foo", html.find("textarea").value
  end
end
