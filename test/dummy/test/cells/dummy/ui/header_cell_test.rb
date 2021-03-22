# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/header", nil).(:show)
    assert html.has_css?(".d-ui-header")
  end
end
