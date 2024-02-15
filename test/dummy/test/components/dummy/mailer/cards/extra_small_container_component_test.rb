# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::Cards::ExtraSmallContainerComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Mailer::Cards::ExtraSmallContainerComponent.new(model:))

    assert_selector(".d-mailer-cards-extra-small-container")
  end
end
