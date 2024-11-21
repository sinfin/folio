# frozen_string_literal: true

class Folio::Captcha::TurnstileComponent < Folio::ApplicationComponent
  def initialize
  end

  def render?
    ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"].present?
  end

  def data
    stimulus_merge_data(
      stimulus_controller("f-captcha-turnstile",
                          values: {
                            site_key: ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"]
                          }),
      stimulus_target("turnstileContainer")
    )
  end
end
