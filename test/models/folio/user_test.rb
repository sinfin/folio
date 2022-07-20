# frozen_string_literal: true

require "test_helper"

class Folio::UserTest < ActiveSupport::TestCase
  test "newsletter subscription" do
    user = Folio::User.invite!(email: "email@email.email",
                               first_name: "John",
                               last_name: "Doe",
                               subscribed_to_newsletter: true) do |u|
      u.skip_invitation = true
    end
    assert_not user.newsletter_subscription

    token = user.instance_variable_get(:@raw_invitation_token)
    user = Folio::User.accept_invitation!(invitation_token: token, password: "12345678", password_confirmation: "12345678")
    assert user.newsletter_subscription
    assert user.newsletter_subscription.active?

    assert 1, Folio::NewsletterSubscription.count
    user.destroy!
    assert 0, Folio::NewsletterSubscription.count
  end

  test "do not stores second address if it is not in use" do
    user = create(:folio_user, primary_address: nil)

    assert_nil user.primary_address
    assert_nil user.secondary_address
    assert_not user.use_secondary_address

    params = {
      use_secondary_address: "0",
      secondary_address_attributes: {
        name: "Foo Von Bar",
        company_name: "",
        address_line_1: "Example steet 75",
        address_line_2: "",
        city: "Somewhere",
        zip: "12345",
        country_code: "CZ"
      }
    }

    assert user.update(params)

    assert_not user.reload.use_secondary_address
    assert_nil user.secondary_address

    assert user.update(params.merge(use_secondary_address: "1"))

    assert user.reload.use_secondary_address
    assert_equal "Somewhere", user.secondary_address.city
  end
end
