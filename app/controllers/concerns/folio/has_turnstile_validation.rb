# frozen_string_literal: true

module Folio::HasTurnstileValidation
  extend ActiveSupport::Concern

  included do
    before_action :validate_turnstile, only: [:create], if: -> {
      Folio::Security.captcha_provider == :turnstile
    }
  end

  private
    def validate_turnstile
      token = params["cf-turnstile-response"]

      if token.blank?
        respond_with_turnstile_failure
        return
      end

      uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
      response = Net::HTTP.post_form(uri, secret: Folio::Security.cloudflare_turnstile_secret_key, response: token)
      result = JSON.parse(response.body)

      unless result["success"]
        respond_with_turnstile_failure
      end
    end

    def respond_with_turnstile_failure
      redirect_path = defined?(turnstile_failure_redirect_path) ? turnstile_failure_redirect_path : root_path

      respond_to do |format|
        format.html {
          set_flash_message(:alert, :turnstile_failure, scope: "folio.devise")
          redirect_to redirect_path
        }
        format.json { render json: { error: t("folio.devise.turnstile_failure") }, status: :unprocessable_entity }
      end
    end
end
