# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::CardComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Mailer::CardComponent.new(title: "foo") { "<p>bar</p>" })

    assert_selector(".d-mailer-card")
  end
end
