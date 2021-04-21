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
    html = Nokogiri::HTML(response.body)
    assert_equal 0, html.css(".folio-newsletter-subscription-form-message").size
    assert_equal 1, html.css(".form-group-invalid #newsletter_subscription_email").size
  end

  test "valid" do
    post newsletter_subscriptions_path, params: {
      newsletter_subscription: {
        email: "foo@bar.baz",
      }
    }
    assert_response(:success)
    html = Nokogiri::HTML(response.body)
    assert_equal 1, html.css(".folio-newsletter-subscription-form-message").size
  end
end
