# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::ButtonComponentTest < Folio::ComponentTest
  def test_render
    label = "hello"
    href = "#"

    render_inline(Dummy::Mailer::ButtonComponent.new(label:, href:))

    assert_selector(".d-mailer-button")
  end
end
