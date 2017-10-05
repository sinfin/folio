# frozen_string_literal: true

require_dependency 'folio/application_controller'

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
        @subscription = Folio::NewsletterSubscription.find(params[:id])
      end
  end
end
