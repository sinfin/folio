# frozen_string_literal: true

module Folio::Captcha::HasRecaptchaValidation
  extend ActiveSupport::Concern

  private
    def validate_recaptcha
      return unless ENV["RECAPTCHA_SITE_KEY"] && !Rails.env.test?

      # FIXME: just a quick fix,this should be implemented differently, invalid recaptcha should render model with error
      respond_with_recaptcha_failure unless verify_recaptcha
    end

    def respond_with_recaptcha_failure
      respond_to do |format|
        format.html {
          redirect_to recaptcha_failure_redirect_path, flash: { alert: t("folio.captcha.failure") }
        }
        format.json { render json: { error: t("folio.captcha.failure") }, status: :unprocessable_entity }
      end
    end

    def recaptcha_failure_redirect_path
      "/"
    end

    # disable default flash error
    def recaptcha_flash_supported?
      false
    end
end
