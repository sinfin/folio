# frozen_string_literal: true

require "test_helper"

class Folio::UserTest < ActiveSupport::TestCase
  test "newsletter subscriptions / single site" do
    site_1 = create_site(force: true)
    site_2 = create_site(force: true) # should have no subscriptions

    [true, false].each_with_index do |subscribed_to_newsletter, i|
      user = Folio::User.invite!(email: "email-#{i}@email.email",
                                 first_name: "John",
                                 last_name: "Doe",
                                 auth_site_id: site_1.id,
                                 subscribed_to_newsletter:) do |u|
        u.skip_invitation = true
      end
      assert_empty user.newsletter_subscriptions.reload

      assert_difference("Folio::NewsletterSubscription.count", 1) do
        assert_difference("Folio::NewsletterSubscription.active.count",
                          subscribed_to_newsletter ? 1 : 0) do
          user.accept_invitation!
        end
      end

      assert_equal subscribed_to_newsletter, user.newsletter_subscriptions.active.present?

      if subscribed_to_newsletter
        assert_equal 1, Folio::NewsletterSubscription.by_site(site_1).active.count
      else
        assert_equal 0, Folio::NewsletterSubscription.by_site(site_1).active.count
      end

      # User is subscribed only to his auth_site
      assert_equal 0, Folio::NewsletterSubscription.by_site(site_2).count

      user.destroy!
      assert_equal 0, Folio::NewsletterSubscription.by_site(site_1).count
    end
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

  test " unless crossdomian enabled, You can create users with same email on different sites" do
    site1 = create(:folio_site, type: "Folio::Site")
    site2 = create(:folio_site, type: "Folio::Site")
    email = "some@email.com"

    Rails.application.config.stub(:folio_crossdomain_devise, false) do
      user1 = build(:folio_user, email:, auth_site: site1)
      assert user1.save
      user2 = build(:folio_user, email:, auth_site: site2)
      assert user2.save

      user1b = build(:folio_user, email:, auth_site: site1)
      assert_not user1b.save
      assert user1b.errors[:email].present?
    end
  end

  test "devise timeoutable" do
    user = create(:folio_user, :superadmin)
    assert_equal false, user.timedout?(Time.current)
    assert_equal true, user.timedout?(31.minutes.ago)
  end

  test "validates password complexity" do
    user = build(:folio_user, password: "weak")
    assert_not user.valid?
    assert_equal 1, user.errors.size
    assert_equal :password, user.errors.first.attribute
    assert_equal :too_short, user.errors.first.type

    user.password = "weakpassword"
    assert_not user.valid?
    assert_equal 3, user.errors.size
    assert_equal %i[password password password],
                 user.errors.map(&:attribute)
    assert_equal %i[missing_uppercase missing_digit missing_special].sort,
                 user.errors.map(&:type).sort

    user.password = "weak password"
    assert_not user.valid?
    assert_equal 3, user.errors.size
    assert_equal %i[password password password],
                 user.errors.map(&:attribute)
    assert_equal %i[missing_uppercase missing_digit missing_special].sort,
                 user.errors.map(&:type).sort

    user.password = "a very long full lowercase password is fine if over forty eight characters long"
    assert user.valid?

    user.password = "Short, but 2 complex!"
    assert user.valid?
  end
end
