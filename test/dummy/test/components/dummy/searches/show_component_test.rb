# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::ShowComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Searches::ShowComponent.new(model:))

    assert_selector(".d-searches-show")
  end
end
