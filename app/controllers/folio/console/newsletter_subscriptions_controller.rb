# frozen_string_literal: true

class Folio::Console::NewsletterSubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::NewsletterSubscription"

  def index
    @newsletter_subscriptions = @newsletter_subscriptions

    respond_with(@newsletter_subscriptions) do |format|
      format.html do
        @pagy, @newsletter_subscriptions = pagy(@newsletter_subscriptions)
      end
      format.csv { render_csv(@newsletter_subscriptions) }
    end
  end
end
