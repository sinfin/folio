# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::AutocompleteCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/searches/autocomplete", nil).(:show)
    assert html.has_css?(".d-searches-autocomplete")
  end
end
