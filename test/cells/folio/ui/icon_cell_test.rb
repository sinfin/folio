# frozen_string_literal: true

require "test_helper"

class Folio::Ui::IconCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/ui/icon", :close).(:show)
    assert html.has_css?(".f-ui-icon")
    assert html.has_css?(".f-ui-icon--close")
  end
end
