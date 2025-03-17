# frozen_string_literal: true

require "test_helper"

class Folio::Console::Links::ValueComponentTest < Folio::Console::ComponentTest
  def test_render
    url_json = {
      href: "/foo"
    }

    render_inline(Folio::Console::Links::ValueComponent.new(url_json:))

    assert_selector(".f-c-links-value")
  end
end
