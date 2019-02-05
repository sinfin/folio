# frozen_string_literal: true

class Folio::NewsletterSubscriptionsController < Folio::ApplicationController
  def create
    attrs = newsletter_subscription_params.merge(visit: current_visit)
    @newsletter_subscription = Folio::NewsletterSubscription.new(attrs)
    success = @newsletter_subscription.save

    Folio::NewsletterSubscriptionMailer.notification_email(@newsletter_subscription).deliver_later if success

    render html: cell('folio/newsletter_subscription_form', @newsletter_subscription, cell_options_params)
  end

  private

    def newsletter_subscription_params
      params.require(:newsletter_subscription).permit(:email)
    end

    def cell_options_params
      cell_options = params[:cell_options]
      if cell_options
        cell_options.permit(:placeholder, :submit_text, :message, :button_class)
      else
        {}
      end
    end
end
