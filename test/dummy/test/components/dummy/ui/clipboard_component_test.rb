# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ClipboardComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::ClipboardComponent.new(model:))

    assert_selector(".d-ui-clipboard")
  end
end
