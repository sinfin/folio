# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::ResultsListComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Searches::ResultsListComponent.new(model:))

    assert_selector(".d-searches-results-list")
  end
end
