# frozen_string_literal: true

require "test_helper"

class Folio::UserTest < ActiveSupport::TestCase
  test "newsletter subscriptions / singleton site" do
    [true, false].each_with_index do |subscribed_to_newsletter, i|
      user = Folio::User.invite!(email: "email-#{i}@email.email",
                                 first_name: "John",
                                 last_name: "Doe",
                                 subscribed_to_newsletter:) do |u|
        u.skip_invitation = true
      end
      assert_empty user.newsletter_subscriptions

      user.accept_invitation!
      assert_equal subscribed_to_newsletter, user.newsletter_subscriptions.present?

      expected_count = subscribed_to_newsletter ? 1 : 0
      assert_equal expected_count, Folio::NewsletterSubscription.count
      user.destroy!
      assert_equal 0, Folio::NewsletterSubscription.count
    end
  end

  test "newsletter subscriptions / multiple sites" do
    skip "TODO: site.newsletter_subscriptions is not available in tests"
  end

  test "do not store second address if it is not in use" do
    user = create(:folio_user, primary_address: nil)

    assert_nil user.primary_address
    assert_nil user.secondary_address
    assert_not user.use_secondary_address

    params = {
      use_secondary_address: "0",
      secondary_address_attributes: {
        name: "Foo Von Bar",
        company_name: "",
        address_line_1: "Example steet",
        address_line_2: "75",
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

  test "scope by_full_name_query" do
    user = create(:folio_user, first_name: "foo", last_name: "bar")

    assert Folio::User.by_full_name_query("foo bar").exists?(id: user.id)
    assert Folio::User.by_full_name_query("foo").exists?(id: user.id)
    assert Folio::User.by_full_name_query("bar").exists?(id: user.id)
    assert Folio::User.by_full_name_query("fo").exists?(id: user.id)
    assert Folio::User.by_full_name_query("ba").exists?(id: user.id)
    assert_not Folio::User.by_full_name_query("xaxa").exists?(id: user.id)
  end

  test "scope by_address_identification_number_query" do
    primary_address = create(:folio_address_primary, identification_number: "123456789")
    user = create(:folio_user, primary_address:)

    assert Folio::User.by_address_identification_number_query("1234").exists?(id: user.id)
    assert Folio::User.by_address_identification_number_query("5678").exists?(id: user.id)
    assert_not Folio::User.by_address_identification_number_query("5607").exists?(id: user.id)
  end

  test "scope by_addresses_query" do
    primary_address = create(:folio_address_primary,
                             name: "Lorem Ipsum",
                             address_line_1: "Downing Street 10",
                             city: "London",
                             zip: "12345")
    user = create(:folio_user, primary_address:)

    assert Folio::User.by_addresses_query("Downing Street 10").exists?(id: user.id)
    assert Folio::User.by_addresses_query("Downing").exists?(id: user.id)
    assert Folio::User.by_addresses_query("10").exists?(id: user.id)
    assert Folio::User.by_addresses_query("London").exists?(id: user.id)
    assert Folio::User.by_addresses_query("Lorem").exists?(id: user.id)
    assert Folio::User.by_addresses_query("Ips").exists?(id: user.id)
    assert Folio::User.by_addresses_query("12345").exists?(id: user.id)
    assert_not Folio::User.by_addresses_query("xaxa").exists?(id: user.id)
  end

  test "scope by_email_query" do
    user = create(:folio_user, email: "foo@bar.baz")

    assert Folio::User.by_email_query("foo").exists?(id: user.id)
    assert Folio::User.by_email_query("fo").exists?(id: user.id)
    assert Folio::User.by_email_query("bar").exists?(id: user.id)
    assert Folio::User.by_email_query("ba").exists?(id: user.id)
    assert Folio::User.by_email_query(".baz").exists?(id: user.id)
    assert Folio::User.by_email_query("@bar.baz").exists?(id: user.id)
    assert Folio::User.by_email_query("@bar").exists?(id: user.id)
    assert_not Folio::User.by_email_query("xaxa").exists?(id: user.id)
  end
end
