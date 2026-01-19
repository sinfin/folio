# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Mailer::LayoutComponentTest < Folio::ComponentTest
  def test_render
    site = create_site

    render_inline(Dummy::Mailer::LayoutComponent.new(site:))

    assert_selector(".d-mailer-layout")
  end
end
