# frozen_string_literal: true

class Folio::NewsletterSubscriptionsController < Folio::ApplicationController
  def create
    @newsletter_subscription = Folio::NewsletterSubscription.new(newsletter_subscription_params)

    if !Rails.application.config.folio_site_is_a_singleton
      @newsletter_subscription.site = current_site
    end

    if validate_turnstile(params["cf-turnstile-response"])
      @newsletter_subscription.save
    else
      @newsletter_subscription.errors.add(:base, :turnstile_verification_failed)
    end

    render html: cell("folio/newsletter_subscriptions/form", @newsletter_subscription, cell_options_params)
  end

  private
    def newsletter_subscription_params
      params.require(:newsletter_subscription).permit(:email,
                                                      tags: [])
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

    def validate_turnstile(response)
      return true if Rails.env.test?
      return true if ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"].nil?
      return false if response.blank?

      secret = ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"]
      uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
      response = Net::HTTP.post_form(uri, secret:, response:)

      result = JSON.parse(response.body)
      result["success"]
    end
end
