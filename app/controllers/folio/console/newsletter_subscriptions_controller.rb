# frozen_string_literal: true

class Folio::Console::NewsletterSubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::NewsletterSubscription'

  def index
    @pagy, @newsletter_subscriptions = pagy(@newsletter_subscriptions)
  end

  def destroy
    @newsletter_subscription.destroy
    respond_with @newsletter_subscription
  end
end
