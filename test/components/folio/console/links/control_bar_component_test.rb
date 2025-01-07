# frozen_string_literal: true

require "test_helper"

class Folio::Console::Links::ControlBarComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Links::ControlBarComponent.new(href: "/foo"))
    assert_selector(".f-c-links-control-bar")
  end
end
