# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Folio::Console::Dummy::TestModalComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Dummy::TestModalComponent.new)

    assert_selector(".f-c-dummy-test-modal")
  end
end
