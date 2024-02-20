# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::Cards::LotComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Mailer::Cards::LotComponent.new(model:))

    assert_selector(".d-mailer-cards-lot")
  end
end
