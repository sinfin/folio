# frozen_string_literal: true

module Folio
  class Console::NewsletterSubscriptionsController < Console::BaseController
    before_action :find_subscription, except: :index
    add_breadcrumb(NewsletterSubscription.model_name.human(count: 2),
                   :console_newsletter_subscriptions_path)

    def index
      if params[:by_query].present?
        subscriptions = NewsletterSubscription.filter_by_params(filter_params)
      else
        subscriptions = NewsletterSubscription.all
      end
      @pagy, @subscriptions = pagy(subscriptions)
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
