# frozen_string_literal: true

module Folio::Captcha::HasTurnstileValidation
  extend ActiveSupport::Concern

  CLOUDFLARE_CHALLENGE_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  included do
    before_action :validate_turnstile, only: [:create], if: -> {
      ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"] && !Rails.env.test?
    }
  end

  private
    def validate_turnstile
      token = params["cf-turnstile-response"]

      if token.blank?
        respond_with_turnstile_failure and return
      end

      uri = URI.parse(CLOUDFLARE_CHALLENGE_URL)
      response = Net::HTTP.post_form(uri, secret: ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"], response: token)
      result = JSON.parse(response.body)

      unless result["success"]
        respond_with_turnstile_failure and return
      end
    end

    def turnstile_failure_redirect_path
      root_path
    end

    def respond_with_turnstile_failure
      respond_to do |format|
        format.html {
          set_flash_message(:alert, :failure, scope: "folio.captcha.turnstile")
          redirect_to turnstile_failure_redirect_path
        }
        format.json { render json: { error: t("folio.captcha.turnstile.failure") }, status: :unprocessable_entity }
      end
    end
end
