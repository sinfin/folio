# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::CardsComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::CardsComponent.new(cards: [{ title: "title" }]))

    assert_selector(".d-ui-cards")
  end
end
