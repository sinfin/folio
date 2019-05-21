# frozen_string_literal: true

require 'gibbon'

class Folio::Mailchimp::SubscribeJob < ApplicationJob
  queue_as :default

  def perform(model, merge_vars: {}, status:)
    api_key = ENV['MAILCHIMP_API_KEY']
    list_id = ENV['MAILCHIMP_LIST_ID']
    raise 'MAILCHIMP_API_KEY or MAILCHIMP_LIST_ID missing' unless api_key && list_id

    subscription = {
      email_address: model.email,
      merge_fields: merge_vars,
      status: status || 'pending'
    }

    mailchimp = Gibbon::Request.new(api_key: api_key)
    mailchimp.lists(list_id).members.create(body: subscription)
  end
end
