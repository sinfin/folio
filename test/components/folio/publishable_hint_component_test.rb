# frozen_string_literal: true

require "test_helper"

class Folio::PublishableHintComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::PublishableHintComponent.new(model:))

    assert_selector(".f-publishable-hint")
  end
end
