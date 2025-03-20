# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::InputClipboardCopyComponentTest < Folio::Console::ComponentTest
  def test_render
    string = "hello"

    render_inline(Folio::Console::Ui::InputClipboardCopyComponent.new(string:))

    assert_selector(".f-c-ui-input-clipboard-copy")
  end
end
