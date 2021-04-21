# frozen_string_literal: true

class Folio::Mailchimp::UnsubscribeJob < ApplicationJob
  queue_as :default

  def perform(model)
    Folio::Mailchimp::Api.new.delete_member(model.email)
  end
end
