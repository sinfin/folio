# frozen_string_literal: true

require "gibbon"

class Folio::Mailchimp::UnsubscribeJob < ApplicationJob
  queue_as :default

  def perform(model)
    api_key = ENV["MAILCHIMP_API_KEY"]
    list_id = ENV["MAILCHIMP_LIST_ID"]
    raise "MAILCHIMP_API_KEY or MAILCHIMP_LIST_ID missing" unless api_key && list_id

    subscription_id = Digest::MD5.hexdigest(model.email)

    mailchimp = Gibbon::Request.new(api_key: api_key)
    mailchimp.lists(list_id).members(subscription_id).delete
  rescue Gibbon::MailChimpError => e
    # ignore pending subscriptions
    raise e unless e.body["status"] == 405
  end
end
