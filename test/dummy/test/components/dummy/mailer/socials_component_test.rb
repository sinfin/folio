# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::SocialsComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Mailer::SocialsComponent.new(model:))

    assert_selector(".d-mailer-socials")
  end
end
