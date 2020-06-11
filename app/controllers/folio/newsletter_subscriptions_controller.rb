# frozen_string_literal: true

class Folio::NewsletterSubscriptionsController < Folio::ApplicationController
  def create
    attrs = newsletter_subscription_params.merge(visit: current_visit)
    @newsletter_subscription = Folio::NewsletterSubscription.new(attrs)
    @newsletter_subscription.save

    render html: cell('folio/newsletter_subscription_form', @newsletter_subscription, cell_options_params)
  end

  private

    def newsletter_subscription_params
      params.require(:newsletter_subscription).permit(:email, :mailchimp_tags)
    end

    def cell_options_params
      cell_options = params[:cell_options]
      if cell_options
        cell_options.permit(:placeholder,
                            :submit_text,
                            :message,
                            :button_class,
                            :label)
      else
        {}
      end
    end
end
