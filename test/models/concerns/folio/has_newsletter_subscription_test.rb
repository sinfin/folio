# frozen_string_literal: true

require "test_helper"

class Folio::HasNewsletterSubscriptionTest < ActiveSupport::TestCase
  test "newsletter subscription gets created & updated" do
    create(:folio_site)

    user = create(:folio_user, email: "email@email.email")
    assert_not user.newsletter_subscription

    user.update!(subscribed_to_newsletter: true)
    assert user.newsletter_subscription
    assert user.newsletter_subscription.active?
    assert_equal "email@email.email", user.newsletter_subscription.email

    user.email = "test@test.test"
    user.skip_reconfirmation! if ::Rails.application.config.folio_users_confirmable
    user.save!

    assert_equal "test@test.test", user.newsletter_subscription.email

    user.update!(subscribed_to_newsletter: false)
    assert_not user.newsletter_subscription.active?
  end
end
