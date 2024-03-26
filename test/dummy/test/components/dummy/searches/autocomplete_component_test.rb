# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::AutocompleteComponentTest < Folio::ComponentTest
  def test_render
    search = { klasses: {}, count: 0, tabs: [], active_results: nil }

    render_inline(Dummy::Searches::AutocompleteComponent.new(search:))

    assert_selector(".d-searches-autocomplete")
  end
end
