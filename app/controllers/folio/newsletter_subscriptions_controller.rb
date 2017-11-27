# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class NewsletterSubscriptionsController < ApplicationController
    def create
      @newsletter_subscription = NewsletterSubscription.new(newsletter_subscription_params)
      success = @newsletter_subscription.save

      NewsletterSubscriptionMailer.notification_email(@newsletter_subscription).deliver_later if success

      render html: cell('folio/newsletter_subscription_form', @newsletter_subscription)
    end

    private

      def newsletter_subscription_params
        params.require(:newsletter_subscription).permit(:email)
      end
  end
end
