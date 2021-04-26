# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::TabsCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/tabs", nil).(:show)
    assert_not html.has_css?(".d-ui-tabs")

    model = [
      { href: "#", active: true, label: "Current tab" },
      { href: "#", label: "Another tab" },
      { href: "#", label: "Another tab" },
    ]

    html = cell("dummy/ui/tabs", model).(:show)
    assert html.has_css?(".d-ui-tabs")
  end
end
