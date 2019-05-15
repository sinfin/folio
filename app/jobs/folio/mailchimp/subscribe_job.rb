# frozen_string_literal: true

require 'mailchimp'

class Folio::Mailchimp::SubscribeJob < ApplicationJob
  queue_as :default

  def perform(model, merge_vars = {})
    api_key = ENV['MAILCHIMP_API_KEY']
    list_id = ENV['MAILCHIMP_LIST_ID']
    raise 'MAILCHIMP_API_KEY or MAILCHIMP_LIST_ID missing' unless api_key && list_id

    mailchimp = Mailchimp::API.new(api_key)
    subscription = { email: model.email }

    mailchimp.lists.subscribe(list_id,
                              subscription,
                              merge_vars)
  end
end
