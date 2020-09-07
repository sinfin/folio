# frozen_string_literal: true

require "test_helper"

class Folio::PhotoswipeCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/photoswipe", nil).(:show)
    assert html.has_css?(".f-photoswipe")
  end
end
