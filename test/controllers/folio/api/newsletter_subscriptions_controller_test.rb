# frozen_string_literal: true

require "test_helper"

class Folio::Api::NewsletterSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  def setup
    create_and_host_site
  end

  test "invalid" do
    post folio_api_newsletter_subscriptions_path(format: :json), params: {
      newsletter_subscription: {
        email: "",
      }
    }
    assert_response(:success)

    data = response.parsed_body["data"]

    assert data.exclude?("f-newsletter-subscriptions-form f-newsletter-subscriptions-form--persisted")
    assert data.include?("f-newsletter-subscriptions-form f-newsletter-subscriptions-form--invalid")
  end

  test "valid" do
    post folio_api_newsletter_subscriptions_path(format: :json), params: {
      newsletter_subscription: {
        email: "foo@bar.baz",
      }
    }
    assert_response(:success)

    data = response.parsed_body["data"]

    assert data.include?("f-newsletter-subscriptions-form f-newsletter-subscriptions-form--persisted")
    assert data.exclude?("f-newsletter-subscriptions-form f-newsletter-subscriptions-form--invalid")
  end
end
