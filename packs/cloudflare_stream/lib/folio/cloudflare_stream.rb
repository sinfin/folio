# frozen_string_literal: true

module Folio::CloudflareStream
  PROVIDER_KEY = "cloudflare_stream"
  VIDEO_PROVIDER_CLASS_NAME = "Folio::CloudflareStream::VideoProvider"

  class << self
    def register_video_provider!
      config = Rails.application.config

      config.folio_files_video_playback_provider_classes =
        config.folio_files_video_playback_provider_classes.merge(PROVIDER_KEY => VIDEO_PROVIDER_CLASS_NAME)

      set_config_default(config, :folio_cloudflare_stream_account_id, ENV["CLOUDFLARE_STREAM_ACCOUNT_ID"])
      set_config_default(config, :folio_cloudflare_stream_api_token, ENV["CLOUDFLARE_STREAM_API_TOKEN"])
      set_config_default(
        config,
        :folio_cloudflare_stream_allowed_origins,
        ENV["CLOUDFLARE_STREAM_ALLOWED_ORIGINS"].to_s.split(",").map(&:strip).compact_blank,
      )
      config.folio_cloudflare_stream_require_signed_urls =
        false unless config.respond_to?(:folio_cloudflare_stream_require_signed_urls)
      set_config_default(config, :folio_cloudflare_stream_source_url_expires_in, 2.hours)
      set_config_default(
        config,
        :folio_cloudflare_stream_signed_url_token_expires_in,
        (ENV["CLOUDFLARE_STREAM_SIGNED_URL_TOKEN_EXPIRES_IN"].presence || 1.hour.to_i).to_i.seconds,
      )
      set_config_default(config, :folio_cloudflare_stream_poll_interval, 30.seconds)
      set_config_default(config, :folio_cloudflare_stream_max_poll_attempts, 240)
      set_config_default(config, :folio_cloudflare_stream_api_open_timeout, 5)
      set_config_default(config, :folio_cloudflare_stream_api_read_timeout, 30)
      set_config_default(config, :folio_cloudflare_stream_api_write_timeout, 30)
      set_config_default(
        config,
        :folio_cloudflare_stream_monitor_stale_after,
        (ENV["CLOUDFLARE_STREAM_MONITOR_STALE_AFTER"].presence || 5.minutes.to_i).to_i.seconds,
      )
    end

    private
      def set_config_default(config, key, value)
        current = config.public_send(key) if config.respond_to?(key)
        config.public_send("#{key}=", current.nil? ? value : current)
      end
  end
end

Folio::CloudflareStream.register_video_provider! if defined?(Rails)
