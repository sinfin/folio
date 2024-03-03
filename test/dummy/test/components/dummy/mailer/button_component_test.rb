# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::ButtonComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Mailer::ButtonComponent.new(model:))

    assert_selector(".d-mailer-button")
  end
end
