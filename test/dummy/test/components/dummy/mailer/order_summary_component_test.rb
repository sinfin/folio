# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::OrderSummaryComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Mailer::OrderSummaryComponent.new(model:))

    assert_selector(".d-mailer-order-summary")
  end
end
