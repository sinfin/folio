# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::IconCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/icon", :alert_triangle).(:show)
    assert html.has_css?(".d-ui-icon")
    assert html.has_css?(".d-ui-icon--alert_triangle")
  end
end
