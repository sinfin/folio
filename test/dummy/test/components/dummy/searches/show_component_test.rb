# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::ShowComponentTest < Folio::ComponentTest
  def test_render

    render_inline(Dummy::Searches::ShowComponent.new(search: @search))

    assert_selector(".d-searches-show")
  end
end
