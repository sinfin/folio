# frozen_string_literal: true

require "gibbon"

class Folio::Mailchimp::Api
  attr_reader :api_key,
              :list_id

  def initialize
    @api_key = ENV.fetch("MAILCHIMP_API_KEY")
    @list_id = ENV.fetch("MAILCHIMP_LIST_ID")
  end

  def request
    Gibbon::Request.new(api_key:)
  end

  def retrieve_member(email, hashed_email: false)
    subscription_id = hashed_email ? email : subscription_id_for(email)

    with_mailchimp_error_rescue do
      request.lists(list_id).members(subscription_id)
                            .retrieve
                            .body
    end
  end

  def create_or_update_member(email, merge_vars: nil, status: "pending")
    subscription_id = subscription_id_for(email)
    current_status = retrieve_member(subscription_id, hashed_email: true).try(:[], "status")

    status = "subscribed" if status == "pending" && current_status == "subscribed"

    subscription = {
      email_address: email,
      merge_fields: merge_vars,
      status:
    }.compact

    request.lists(list_id).members(subscription_id)
                          .upsert(body: subscription)
                          .body
  end

  def delete_member(email)
    subscription_id = subscription_id_for(email)
    member = retrieve_member(subscription_id, hashed_email: true)

    if member && member["status"] != "archived"
      # to archive pending member is not allowed, make him subscribed first
      if member["status"] == "pending"
        request.lists(list_id).members(subscription_id)
                              .upsert(body: { status: "subscribed" })
      end

      request.lists(list_id).members(subscription_id)
                            .delete

      true
    end
  end

  def retrieve_member_tags(email)
    subscription_id = subscription_id_for(email)

    with_mailchimp_error_rescue do
      request.lists(list_id).members(subscription_id).tags
                                                     .retrieve
                                                     .body
                                                     .try(:[], "tags")
    end
  end

  def add_member_tags(email, tags)
    subscription_id = subscription_id_for(email)
    tags = tags.map { |t| { name: t, status: "active" } }

    with_mailchimp_error_rescue do
      request.lists(list_id).members(subscription_id).tags
                                                     .create(body: { tags: })
    end

    true
  end

  private
    def subscription_id_for(email)
      Digest::MD5.hexdigest(email.downcase)
    end

    def with_mailchimp_error_rescue
      yield
    rescue Gibbon::MailChimpError => e
      raise e unless e.status_code == 404
    end
end
