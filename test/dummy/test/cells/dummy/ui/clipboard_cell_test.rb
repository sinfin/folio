# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ClipboardCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/clipboard", nil).(:show)
    assert html.has_css?(".d-ui-clipboard")
  end
end
