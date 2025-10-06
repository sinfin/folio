# frozen_string_literal: true

require "test_helper"

class Folio::Embed::BoxComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Embed::BoxComponent.new(model:))

    assert_selector(".f-embed-box")
  end
end
