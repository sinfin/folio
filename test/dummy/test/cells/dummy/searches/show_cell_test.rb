# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::ShowCellTest < Cell::TestCase
  test "show" do
    model = {
      klasses: {},
      count: 0,
      tabs: [],
      active_results: nil,
    }

    html = cell("dummy/searches/show", model).(:show)
    assert html.has_css?(".d-searches-show")
    assert_not html.has_css?(".d-searches-show__results")
    assert_not html.has_css?(".d-searches-show__tabs")
    assert_equal "", html.find(".d-searches-show__tabs").text

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

    html = cell("dummy/searches/show", model).(:show)
    assert html.has_css?(".d-searches-show")
    assert html.has_css?(".d-searches-show__results")
    assert_not_equal "", html.find(".d-searches-show__tabs").text
  end
end
