# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::SocialsComponentTest < Folio::ComponentTest
  def test_render
    site = create(:folio_site)

    render_inline(Dummy::Mailer::SocialsComponent.new(site:))

    assert_selector(".d-mailer-socials")
  end
end
