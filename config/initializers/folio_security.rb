# frozen_string_literal: true

module Folio
  class Security
    # Možné hodnoty: :turnstile, :recaptcha, nil
    mattr_accessor :captcha_provider
    @@captcha_provider = ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"].present? ? :turnstile : nil

    mattr_accessor :cloudflare_turnstile_site_key
    @@cloudflare_turnstile_site_key = ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"]

    mattr_accessor :cloudflare_turnstile_secret_key
    @@cloudflare_turnstile_secret_key = ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"]

    # Possible future implementation
    # mattr_accessor :recaptcha_site_key
    # @@recaptcha_site_key = ENV["RECAPTCHA_SITE_KEY"]

    # mattr_accessor :recaptcha_secret_key
    # @@recaptcha_secret_key = ENV["RECAPTCHA_SECRET_KEY"]
  end
end
