# frozen_string_literal: true

require "test_helper"

class Folio::Console::Atoms::WordCountComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Atoms::WordCountComponent.new)

    assert_selector(".f-c-atoms-word-count")
  end
end
