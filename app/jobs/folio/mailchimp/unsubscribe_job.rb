# frozen_string_literal: true

class Folio::Mailchimp::UnsubscribeJob < ApplicationJob
  queue_as :default

  # deprecated, use Folio::HasNewsletterSubscriptions & Folio::Mailchimp::CreateOrUpdateSubscriptionJob

  def perform(email)
    Folio::Mailchimp::Api.new.delete_member(email)
  end
end
