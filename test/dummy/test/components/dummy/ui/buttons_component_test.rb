# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::ButtonsComponentTest < ViewComponent::TestCase
  def test_render
    buttons = [
      { label: "hello" },
      { label: "world" },
    ]

    render_inline(Dummy::Ui::ButtonsComponent.new(buttons:))

    assert_selector(".d-ui-buttons")
    assert_selector(".d-ui-button", count: 2)
  end
end
