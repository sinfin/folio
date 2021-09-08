# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderSearchCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/header_search", nil).(:show)
    assert html.has_css?(".d-ui-header-search")
  end
end
