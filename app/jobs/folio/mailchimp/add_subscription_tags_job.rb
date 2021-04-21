# frozen_string_literal: true

class Folio::Mailchimp::AddSubscriptionTagsJob < ApplicationJob
  queue_as :default

  def perform(model, tags)
    Folio::Mailchimp::Api.new.add_member_tags(model.email, tags)
  end
end
