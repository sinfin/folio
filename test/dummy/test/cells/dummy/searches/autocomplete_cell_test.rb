# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::AutocompleteCellTest < Cell::TestCase
  test "show" do
    model = {
      klasses: {},
      count: 0,
      tabs: [],
      active_results: nil,
    }

    html = cell("dummy/searches/autocomplete", model).(:show)
    assert html.has_css?(".d-searches-autocomplete")
    assert_not html.has_css?(".d-searches-autocomplete__klass")

    model = {
      klasses: {
        Folio::Page => {
          pagy: nil,
          records: create_list(:folio_page, 1),
          count: 1,
          label: "Pages (1)",
          href: "#foo",
          results_cell: "dummy/searches/results_list",
        },
      },
      count: 1,
      tabs: [
        {
          label: "Pages (1)",
          active: true,
          href: "#foo",
        }
      ],
      active_results: nil,
    }

    html = cell("dummy/searches/autocomplete", model).(:show)
    assert html.has_css?(".d-searches-autocomplete")
    assert html.has_css?(".d-searches-autocomplete__klass")
  end
end
