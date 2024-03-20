# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::FooterComponentTest < Folio::ComponentTest
  def test_render
    site = create(:folio_site)

    render_inline(Dummy::Mailer::FooterComponent.new(site:))

    assert_selector(".d-mailer-footer")
  end
end
