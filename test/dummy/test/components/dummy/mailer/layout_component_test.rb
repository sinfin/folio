# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::LayoutComponentTest < Folio::ComponentTest
  def test_render
    site = create_site

    render_inline(Dummy::Mailer::LayoutComponent.new(site:))

    assert_selector(".d-mailer-layout")
  end
end
