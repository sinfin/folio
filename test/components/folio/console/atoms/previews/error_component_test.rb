# frozen_string_literal: true

require "test_helper"

class Folio::Console::Atoms::Previews::ErrorComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Atoms::Previews::ErrorComponent.new)

    assert_selector(".f-c-atoms-previews-error")
  end
end
