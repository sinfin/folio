# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ClipboardComponentTest < Folio::Console::ComponentTest
  def test_render
    text = "hello"

    render_inline(Folio::Console::Ui::ClipboardComponent.new(text:))

    assert_selector(".f-c-ui-clipboard")
  end

  def test_render_as_a_button
    text = "hello"

    render_inline(Folio::Console::Ui::ClipboardComponent.new(text:, as_button: true))

    assert_selector(".f-c-ui-clipboard")
  end
end
