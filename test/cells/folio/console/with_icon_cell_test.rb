# frozen_string_literal: true

require "test_helper"

class Folio::Console::WithIconCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/with_icon", nil).(:show)
    assert html.has_css?(".f-c-with-icon")
    assert_equal("", html.text)
    assert_not(html.has_css?(".mi"))
    assert_not(html.has_css?(".fa"))

    html = cell("folio/console/with_icon", "foo").(:show)
    assert html.has_css?(".f-c-with-icon")
    assert_equal("foo", html.text)
    assert_not(html.has_css?(".mi"))
    assert_not(html.has_css?(".fa"))

    html = cell("folio/console/with_icon", "foo", mi: "delete").(:show)
    assert html.has_css?(".f-c-with-icon")
    assert_equal("deletefoo", html.text)
    assert(html.has_css?(".mi"))
    assert_not(html.has_css?(".fa"))

    html = cell("folio/console/with_icon", "foo", fa: "eye").(:show)
    assert html.has_css?(".f-c-with-icon")
    assert_equal("foo", html.text)
    assert_not(html.has_css?(".mi"))
    assert(html.has_css?(".fa"))
  end
end
