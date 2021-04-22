# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ShareCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/share", nil).(:show)
    assert html.has_css?(".d-ui-share")
  end
end
