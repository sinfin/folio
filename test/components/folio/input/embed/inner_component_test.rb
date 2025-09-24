# frozen_string_literal: true

require "test_helper"

class Folio::Input::Embed::InnerComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Input::Embed::InnerComponent.new(model:))

    assert_selector(".f-input-embed-inner")
  end
end
