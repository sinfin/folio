# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ButtonsComponentTest < Folio::Console::ComponentTest
  def test_render
    buttons = [
      {
        href: "#foo",
        label: "label",
        icon: :send,
        variant: :warning,
        class_name: "my_class"
      },
      {
        type: :submit,
        label: "label",
        icon: :send,
        variant: :warning,
        class_name: "my_class"
      }
    ]

    render_inline(Folio::Console::Ui::ButtonsComponent.new(buttons:))

    assert_selector(".f-c-ui-buttons")
  end
end
