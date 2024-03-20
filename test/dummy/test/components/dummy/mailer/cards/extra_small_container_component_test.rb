# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::Cards::ExtraSmallContainerComponentTest < Folio::ComponentTest
  def test_render
    cards = [
              {
                title: "Card headline",
                text: "Subtitle",
                href: "#",
                image: Folio::File::Image.first,
              },
              {
                title: "Card headline",
                text: "Subtitle",
              },
            ]

    render_inline(Dummy::Mailer::Cards::ExtraSmallContainerComponent.new(cards:))

    assert_selector(".d-mailer-cards-extra-small-container")
  end
end
