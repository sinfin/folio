# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::HeaderComponentTest < Folio::ComponentTest
  def test_render
    site = create(:folio_site)

    render_inline(Dummy::Mailer::HeaderComponent.new(site:))

    assert_selector(".d-mailer-header")
  end
end
