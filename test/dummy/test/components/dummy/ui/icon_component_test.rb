# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::IconComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::IconComponent.new(name: :close))

    assert_selector(".d-ui-icon")
  end
end
