# frozen_string_literal: true

class Folio::RecaptchaFieldComponent < ApplicationComponent
  include ::Recaptcha::Adapters::ViewMethods

  def initialize(f:)
    @f = f
  end

  def render?
    ENV["RECAPTCHA_SITE_KEY"].present? && ENV["RECAPTCHA_SECRET_KEY"].present?
  end
end
