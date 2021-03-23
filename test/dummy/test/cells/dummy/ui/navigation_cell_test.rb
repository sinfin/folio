# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::NavigationCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/navigation", nil).(:show)
    assert html.has_css?(".d-ui-navigation")
  end
end
