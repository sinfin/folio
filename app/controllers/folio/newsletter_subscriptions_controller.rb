# frozen_string_literal: true

class Folio::NewsletterSubscriptionsController < Folio::ApplicationController
  def create
    attrs = newsletter_subscription_params

    @newsletter_subscription = Folio::NewsletterSubscription.new(attrs)
    @newsletter_subscription = check_recaptcha_if_needed(@newsletter_subscription)

    if !Rails.application.config.folio_site_is_a_singleton
      @newsletter_subscription.site = current_site
    end

    @newsletter_subscription.save

    render html: cell("folio/newsletter_subscriptions/form", @newsletter_subscription, cell_options_params)
  end

  private
    def newsletter_subscription_params
      params.require(:newsletter_subscription).permit(:email)
    end

    def cell_options_params
      cell_options = params[:cell_options]
      if cell_options
        cell_options.permit(:placeholder,
                            :submit_text,
                            :message,
                            :button_class,
                            :label,
                            :input_label)
      else
        {}
      end
    end

    def check_recaptcha_if_needed(newsletter_subscription)
      if ENV["RECAPTCHA_SITE_KEY"].present? &&
         ENV["RECAPTCHA_SECRET_KEY"].present?
        newsletter_subscription.verified_captcha = verify_recaptcha(model: newsletter_subscription)
      end

      newsletter_subscription
    end
end
