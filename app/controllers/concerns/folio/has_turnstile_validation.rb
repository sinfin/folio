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
        format.html { redirect_to redirect_path, alert: "Ov\u011B\u0159en\u00ED captcha selhalo" }
        format.json { render json: { error: "Ov\u011B\u0159en\u00ED captcha selhalo" }, status: :unprocessable_entity }
      end
    end
end
