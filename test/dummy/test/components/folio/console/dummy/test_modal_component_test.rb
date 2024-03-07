# frozen_string_literal: true

require "test_helper"

class Folio::Console::Dummy::TestModalComponentTest < Folio::Console::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Console::Dummy::TestModalComponent.new(model:))

    assert_selector(".f-c-dummy-test-modal")
  end
end
