# frozen_string_literal: true

class Folio::Console::NewsletterSubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::NewsletterSubscription'

  def index
    if params[:by_query].present?
      @newsletter_subscriptions = @newsletter_subscriptions.filter_by_params(filter_params)
    end
    @pagy, @newsletter_subscriptions = pagy(@newsletter_subscriptions)
  end

  def destroy
    @newsletter_subscription.destroy
    respond_with @newsletter_subscription, location: { action: :index }
  end
end
