# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::DisclaimerCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/disclaimer", nil).(:show)
    assert html.has_css?(".d-ui-disclaimer")
  end
end
