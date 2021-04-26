# frozen_string_literal: true

require "test_helper"

class Folio::UserTest < ActiveSupport::TestCase
  test "first_name and last_name validation" do
    user = Folio::User.new(email: "email@email.email",
                           password: "123123123",
                           password_confirmation: "123123123")
    assert_not(user.valid?)
    assert user.errors[:first_name]
    assert user.errors[:last_name]
  end

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
end

# == Schema Information
#
# Table name: folio_users
#
#  id                     :bigint(8)        not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_type        :string
#  invited_by_id          :bigint(8)
#  invitations_count      :integer          default(0)
#
# Indexes
#
#  index_folio_users_on_confirmation_token                 (confirmation_token) UNIQUE
#  index_folio_users_on_email                              (email) UNIQUE
#  index_folio_users_on_invitation_token                   (invitation_token) UNIQUE
#  index_folio_users_on_invited_by_id                      (invited_by_id)
#  index_folio_users_on_invited_by_type_and_invited_by_id  (invited_by_type,invited_by_id)
#  index_folio_users_on_reset_password_token               (reset_password_token) UNIQUE
#
