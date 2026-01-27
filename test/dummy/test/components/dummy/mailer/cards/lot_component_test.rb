# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Mailer::Cards::LotComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Mailer::Cards::LotComponent.new(author: "Author", name: "Item 1"))

    assert_selector(".d-mailer-cards-lot")
  end
end
