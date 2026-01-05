# frozen_string_literal: true

class Folio::Mailchimp::CreateOrUpdateSubscriptionJob < ApplicationJob
  queue_as :default

  unique :until_and_while_executing

  def perform(email)
    return unless mailchimp_api.ready_to_use?

    subscription = Folio::NewsletterSubscription.find_by_email(email)

    if subscription && subscription.active?
      status = subscription.requires_subscription_confirmation? ? "pending" : "subscribed"

      mailchimp_api.create_or_update_member(email,
                                            merge_vars: subscription.merge_vars,
                                            status:)

      if subscription.tags.present?
        mailchimp_api.add_member_tags(email,
                                      subscription.tags)
      end
    else
      mailchimp_api.delete_member(email)
    end
  end

  private
    def mailchimp_api
      @mailchimp_api ||= Folio::Mailchimp::Api.new
    end
end
