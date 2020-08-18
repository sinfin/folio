# frozen_string_literal: true

require "test_helper"

class Folio::Console::LazyDomCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/lazy_dom", "foo").(:show)
    assert html.has_css?(".f-c-lazy-dom")
    assert_equal "foo", html.find(".f-c-lazy-dom").native["data-lazy-dom-url"]
  end
end
