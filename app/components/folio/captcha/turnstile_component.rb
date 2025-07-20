# frozen_string_literal: true

class Folio::Captcha::TurnstileComponent < Folio::ApplicationComponent
  def initialize(appearance: "always", submit_button_class_name: nil)
    @appearance = appearance
    @submit_button_class_name = submit_button_class_name
  end

  def render?
    ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"].present?
  end

  def data
    stimulus_controller("f-captcha-turnstile",
                        values: {
                          site_key: ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"],
                          appearance: @appearance,
                          submit_button_class_name: @submit_button_class_name
                        })
  end
end
