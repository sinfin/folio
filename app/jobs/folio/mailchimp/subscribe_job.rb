# frozen_string_literal: true

class Folio::Mailchimp::SubscribeJob < ApplicationJob
  queue_as :default

  # deprecated, use Folio::HasNewsletterSubscription & Folio::Mailchimp::CreateOrUpdateSubscriptionJob

  def perform(email, merge_vars: {}, tags: [], status: nil)
    mailchimp = Folio::Mailchimp::Api.new
    mailchimp.create_or_update_member(model.email, merge_vars:, status:)
    mailchimp.add_member_tags(model.email, tags)
  end
end
