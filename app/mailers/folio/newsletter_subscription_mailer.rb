# frozen_string_literal: true

module Folio
  class NewsletterSubscriptionMailer < ApplicationMailer
    layout false

    def notification_email(newsletter_subscription)
      @newsletter_subscription = newsletter_subscription
      site = Site.last
      mail(to: site.email,
           subject: "#{site.title} newsletter subscription",
           from: newsletter_subscription.email) do |format|
        format.text
      end
    end
  end
end
