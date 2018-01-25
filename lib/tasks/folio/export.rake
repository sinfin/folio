# frozen_string_literal: true

namespace :folio do
  namespace :export do
    task newsletter: :environment do
      require 'mailchimp'
      Excon.defaults[:ssl_verify_peer] = false

      api_key = ENV['MAILCHIMP_API_KEY']
      list_id = ENV['MAILCHIMP_LIST_ID']
      fail 'MAILCHIMP_API_KEY or MAILCHIMP_LIST_ID missing' unless api_key && list_id

      mailchimp = Mailchimp::API.new(api_key)

      subscriptions = []


      Folio::NewsletterSubscription.where('created_at > ?', 7.days.ago).each do |subscription|
        subscriptions << {
                          'EMAIL' =>
                            {
                              'email' => subscription.email
                            },
                          :EMAIL_TYPE => 'html',
                          :merge_vars => {
                            'STATUS' => 'Subscribed'
                          }
                        }
      end

      subscriptions.reverse.in_groups_of(100) do |group|
        # Now you can simply call the following method and it will do bulk upload at mailchimp.
        mailchimp.lists.batch_subscribe(list_id, group, false, true, false)
      end
    end
  end
end
