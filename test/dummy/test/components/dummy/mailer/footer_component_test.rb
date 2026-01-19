# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Mailer::FooterComponentTest < Folio::ComponentTest
  def test_render
    site = create_site
    create(:dummy_menu_footer)

    render_inline(Dummy::Mailer::FooterComponent.new(site:))

    assert_selector(".d-mailer-footer")
  end
end
