# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::FooterMenuComponentTest < Folio::ComponentTest
  def test_render
    site = create_site
    create(:dummy_menu_footer)

    render_inline(Dummy::Mailer::FooterMenuComponent.new(site:))

    assert_selector(".d-mailer-footer-menu")
  end
end
