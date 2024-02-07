# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::FooterMenuComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Mailer::FooterMenuComponent.new(model:))

    assert_selector(".d-mailer-footer-menu")
  end
end
