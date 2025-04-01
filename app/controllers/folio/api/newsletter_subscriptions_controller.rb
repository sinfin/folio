# frozen_string_literal: true

class Folio::Api::NewsletterSubscriptionsController < Folio::Api::BaseController
  include Folio::Captcha::HasTurnstileValidation

  def create
    newsletter_subscription = Folio::NewsletterSubscription.new(newsletter_subscription_params.merge(site: current_site))
    newsletter_subscription.save

    render_component_json(Folio::NewsletterSubscriptions::FormComponent.new(newsletter_subscription:, view_options: view_options_params))
  end

  private
    def newsletter_subscription_params
      params.require(:newsletter_subscription).permit(:email)
    end

    def view_options_params
      view_option_keys = Folio::NewsletterSubscriptions::FormComponent::REMEMBER_OPTION_KEYS
      view_options = params[:view_options]

      if view_options
        view_options.permit(*view_option_keys)
      else
        {}
      end
    end
end
