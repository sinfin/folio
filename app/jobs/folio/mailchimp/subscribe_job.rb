# frozen_string_literal: true

require 'mailchimp'

class Folio::Mailchimp::SubscribeJob < ApplicationJob
  queue_as :default

  def perform(model, additional_data = {})
    api_key = ENV['MAILCHIMP_API_KEY']
    list_id = ENV['MAILCHIMP_LIST_ID']
    fail 'MAILCHIMP_API_KEY or MAILCHIMP_LIST_ID missing' unless api_key && list_id

    mailchimp = Mailchimp::API.new(api_key)

    subscription = {
      'email' => model.email,
      'FIRSTNAME' => model.try(:first_name),
      'LASTNAME' => model.try(:last_name),
    }.merge(additional_data)

    mailchimp.lists.subscribe(list_id, subscription)
  end
end
