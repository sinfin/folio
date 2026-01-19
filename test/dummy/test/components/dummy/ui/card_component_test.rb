# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::CardComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::CardComponent.new(title: "title"))

    assert_selector(".d-ui-card")
  end
end
