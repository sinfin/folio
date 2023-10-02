# frozen_string_literal: true

require "test_helper"

class Folio::NewsletterSubscriptions::FormComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::NewsletterSubscriptions::FormComponent.new())

    assert_selector(".f-newsletter-subscriptions-form")
  end
end
