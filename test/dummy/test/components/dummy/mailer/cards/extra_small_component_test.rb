# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Mailer::Cards::ExtraSmallComponentTest < Folio::ComponentTest
  def test_render
    card = { title: "Card headline", text: "Subtitle" }

    render_inline(Dummy::Mailer::Cards::ExtraSmallComponent.new(card:))

    assert_selector(".d-mailer-cards-extra-small")
  end
end
