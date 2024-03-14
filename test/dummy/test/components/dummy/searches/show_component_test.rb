# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::ShowComponentTest < Folio::ComponentTest
  def test_render
    search = { klasses: {}, count: 0, tabs: [], active_results: nil }

    render_inline(Dummy::Searches::ShowComponent.new(search:))

    assert_selector(".d-searches-show")
  end
end
