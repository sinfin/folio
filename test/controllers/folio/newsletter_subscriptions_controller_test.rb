# frozen_string_literal: true

require "test_helper"

class Folio::NewsletterSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  def setup
    create(:folio_site)
  end

  test "invalid" do
    post newsletter_subscriptions_path, params: {
      newsletter_subscription: {
        email: "",
      }
    }
    assert_response(:success)
    assert_select(".f-newsletter-subscriptions-form__message", false)
    assert_select(".form-group-invalid .f-newsletter-subscriptions-form__input")
  end

  test "valid" do
    post newsletter_subscriptions_path, params: {
      newsletter_subscription: {
        email: "foo@bar.baz",
      }
    }
    assert_response(:success)
    assert_select(".f-newsletter-subscriptions-form__message")
  end
end
