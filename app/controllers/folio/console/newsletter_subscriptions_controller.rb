# frozen_string_literal: true

module Folio
  class Console::NewsletterSubscriptionsController < Console::BaseController
    before_action :find_subscription, except: :index
    def index
      if params[:by_query].present?
        @subscriptions = NewsletterSubscription.filter(filter_params)
      else
        @subscriptions = NewsletterSubscription.all
      end
      @subscriptions = @subscriptions.page(current_page)
    end

    def destroy
      @subscription.destroy
      respond_with @subscription, location: console_newsletter_subscriptions_path
    end

    private

      def find_subscription
        @subscription = NewsletterSubscription.find(params[:id])
      end
  end
end
