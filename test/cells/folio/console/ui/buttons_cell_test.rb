# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ButtonsCellTest < Folio::Console::CellTest
  test "show" do
    model = [
      {
        href: "#foo",
        label: "label",
        icon: :send,
        variant: :warning,
        class: "my_class"
      },
      {
        action: "submit",
        label: "label",
        icon: :send,
        variant: :warning,
        class: "my_class"
      }
    ]

    html = cell("folio/console/ui/buttons", model).(:show)
    assert html.has_css?(".f-c-ui-buttons")
    assert html.has_css?(".f-c-ui-button")
  end
end
