# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::ResultsListComponentTest < Folio::ComponentTest
  def test_render
    data = { records: create_list(:folio_page, 1) }

    render_inline(Dummy::Searches::ResultsListComponent.new(data:))

    assert_selector(".d-searches-results-list")
    assert_selector(".d-searches-results-list__result")
  end
end
