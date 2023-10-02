# frozen_string_literal: true

class Folio::Api::NewsletterSubscriptionsController < Folio::Api::BaseController
  def create
    newsletter_subscription = Folio::NewsletterSubscription.new(newsletter_subscription_params)

    if !Rails.application.config.folio_site_is_a_singleton
      newsletter_subscription.site = current_site
    end

    newsletter_subscription.save

    render_component_json(Folio::NewsletterSubscriptions::FormComponent.new(newsletter_subscription:, view_options: view_options_params))
  end

  private
    def newsletter_subscription_params
      params.require(:newsletter_subscription).permit(:email)
    end

    def view_options_params
      view_options = params[:view_options]

      if view_options
        view_options.permit(:placeholder,
                            :submit_text,
                            :message,
                            :button_class,
                            :label,
                            :input_label)
      else
        {}
      end
    end
end
