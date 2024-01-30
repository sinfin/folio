# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ClipboardComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::ClipboardComponent.new(text: "Hello world", height: 22))

    assert_selector(".d-ui-clipboard")
  end
end
