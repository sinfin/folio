# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::MiniSelectComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::MiniSelectComponent.new(type: :currency))

    assert_selector(".d-ui-mini-select")
  end
end
