# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::ResultsListCellTest < Cell::TestCase
  test "show" do
    model = create_list(:folio_page, 1)
    html = cell("dummy/searches/results_list", model).(:show)
    assert html.has_css?(".d-searches-results-list")
  end
end
