# frozen_string_literal: true

require "test_helper"

class Folio::NewsletterSubscriptionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "updates mailchimp subscription after commit" do
    ENV["DEV_MAILCHIMP"] = "1"

    subscription = build(:folio_newsletter_subscription, email: "email@email.email")

    assert_enqueued_jobs 1 do
      subscription.save!
    end

    assert_enqueued_jobs 2 do
      subscription.reload.update!(email: "foo@email.email")
    end

    assert_enqueued_jobs 1 do
      subscription.reload.destroy!
    end

    ENV["DEV_MAILCHIMP"] = nil
  end
end

# == Schema Information
#
# Table name: folio_newsletter_subscriptions
#
#  id         :integer          not null, primary key
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
