# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ButtonComponentTest < ViewComponent::TestCase
  def test_render
    label = "hello"

    render_inline(Dummy::Ui::ButtonComponent.new(label:))

    assert_selector(".d-ui-button", text: label)
  end
end
