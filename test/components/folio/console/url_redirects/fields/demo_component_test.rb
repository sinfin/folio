# frozen_string_literal: true

require "test_helper"

class Folio::Console::UrlRedirects::Fields::DemoComponentTest < Folio::Console::ComponentTest
  def test_render
    url_redirect = create(:folio_url_redirect)

    render_inline(Folio::Console::UrlRedirects::Fields::DemoComponent.new(url_redirect:))

    assert_selector(".f-c-url-redirects-fields-demo")
  end
end
