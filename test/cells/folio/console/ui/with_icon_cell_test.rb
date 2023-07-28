# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::WithIconCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/ui/with_icon", nil).(:show)
    assert html.has_css?(".f-c-ui-with-icon")
    assert_equal("", html.text)
    assert_not(html.has_css?(".f-ui-icon"))

    html = cell("folio/console/ui/with_icon", "foo").(:show)
    assert html.has_css?(".f-c-ui-with-icon")
    assert_equal("foo", html.text)
    assert_not(html.has_css?(".f-ui-icon"))

    html = cell("folio/console/ui/with_icon", "foo", icon: :delete).(:show)
    assert html.has_css?(".f-c-ui-with-icon")
    assert_equal("foo", html.text)
    assert(html.has_css?(".f-ui-icon"))
  end
end
