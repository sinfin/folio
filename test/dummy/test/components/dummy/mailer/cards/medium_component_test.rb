# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::Cards::MediumComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Mailer::Cards::MediumComponent.new(title: "foo") { "<p>bar</p>" })

    assert_selector(".d-mailer-cards-medium")
  end
end
