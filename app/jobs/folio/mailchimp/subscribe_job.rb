# frozen_string_literal: true

class Folio::Mailchimp::SubscribeJob < ApplicationJob
  queue_as :default

  def perform(model, merge_vars: {}, tags: [])
    status = model.class.requires_subscription_confirmation? ? "pending" : "subscribed"

    mailchimp = Folio::Mailchimp::Api.new
    mailchimp.create_or_update_member(model.email, merge_vars: merge_vars, status: status)
    mailchimp.add_member_tags(model.email, tags)
  end
end
