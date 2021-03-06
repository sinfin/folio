# frozen_string_literal: true

require "gibbon"

class Folio::Mailchimp::SubscribeJob < ApplicationJob
  queue_as :default

  def perform(model, merge_vars: {}, tags: [])
    api_key = ENV["MAILCHIMP_API_KEY"]
    list_id = ENV["MAILCHIMP_LIST_ID"]
    raise "MAILCHIMP_API_KEY or MAILCHIMP_LIST_ID missing" unless api_key && list_id

    subscription = {
      email_address: model.email,
      merge_fields: merge_vars,
      status: model.class.requires_subscription_confirmation? ? "pending" : "subscribed"
    }
    subscription_id = Digest::MD5.hexdigest(model.email)

    mailchimp = Gibbon::Request.new(api_key: api_key)
    mailchimp.lists(list_id).members(subscription_id)
                            .upsert(body: subscription)

    if tags.present?
      tags = tags.map { |t| { name: t, status: "active" } }
      mailchimp.lists(list_id)
               .members(subscription_id)
               .tags
               .create(body: { tags: tags })
    end
  end
end
