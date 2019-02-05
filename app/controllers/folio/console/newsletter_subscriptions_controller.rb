# frozen_string_literal: true

class Folio::Console::NewsletterSubscriptionsController < Folio::Console::BaseController
  before_action :find_subscription, except: :index
  add_breadcrumb(Folio::NewsletterSubscription.model_name.human(count: 2),
                 :console_newsletter_subscriptions_path)

  def index
    if params[:by_query].present?
      subscriptions = Folio::NewsletterSubscription.filter_by_params(filter_params)
    else
      subscriptions = Folio::NewsletterSubscription.all
    end
    @pagy, @subscriptions = pagy(subscriptions)
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
