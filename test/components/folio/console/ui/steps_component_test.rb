# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::StepsComponentTest < Folio::Console::ComponentTest
  def test_render
    steps = [
      { label: "First step", href: "#{request.path}" },
      { label: "Second step", href: "#{request.path}?step=2" },
      { label: "Third step", href: "#{request.path}?step=3" },
    ]

    render_inline(Folio::Console::Ui::StepsComponent.new(steps:))

    assert_selector(".f-c-ui-steps")
  end
end
