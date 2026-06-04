# frozen_string_literal: true

require "uri"

class Folio::CloudflareStream::VideoProvider < Folio::Video::Providers::Base
  SIGNED_URL_TOKEN_CACHE_SAFETY_MARGIN = 1.minute

  def ready?
    data["ready_to_stream"] == true && playback.values.any?(&:present?)
  end

  def sources
    return [] unless ready?

    [
      source_for("hls", "application/x-mpegURL", "HLS"),
      source_for("dash", "application/dash+xml", "DASH"),
    ].compact
  end

  def embed_url
    playback_url_for(unsigned_embed_url)
  end

  def poster_url
    playback_url_for(unsigned_poster_url)
  end

  def seo_metadata
    {
      title: title.presence,
      description: description.presence,
      thumbnail_url: requires_signed_urls? ? nil : unsigned_poster_url.presence,
      upload_date: video.created_at&.iso8601,
      duration: duration_iso8601,
      content_url: nil,
      embed_url: requires_signed_urls? ? nil : unsigned_embed_url.presence,
    }.compact
  end

  def processing_state
    return "ready" if ready?
    return "failed" if error_message.present? || status_state == "error"
    return "processing" if data["uid"].present?

    super
  end

  private
    def playback
      data["playback"] || {}
    end

    def source_for(key, type, label)
      src = playback[key].presence
      return if src.blank?

      signed_src = playback_url_for(src)
      return if signed_src.blank?

      { src: signed_src, type: type, label: label }
    end

    def status_state
      data.dig("status", "state").to_s
    end

    def unsigned_poster_url
      data["thumbnail"].presence
    end

    def unsigned_embed_url
      data["iframe_url"].presence || iframe_url_from_playback_host
    end

    def iframe_url_from_playback_host
      uid = data["uid"].presence
      url = playback.values.compact_blank.first || data["preview"].presence
      return if uid.blank? || url.blank?

      uri = URI.parse(url)
      "#{uri.scheme}://#{uri.host}/#{uid}/iframe"
    rescue URI::InvalidURIError
      nil
    end

    def requires_signed_urls?
      data["require_signed_urls"] == true || data["requireSignedURLs"] == true
    end

    def playback_url_for(url)
      return url unless requires_signed_urls?

      token = signed_url_token
      return if token.blank? || url.blank?

      replace_playback_identifier(url, token)
    end

    def signed_url_token
      uid = data["uid"].presence
      return if uid.blank?

      @signed_url_token ||= Rails.cache.read(signed_url_token_cache_key(uid)).presence ||
                            fetch_and_cache_signed_url_token(uid)
    rescue Folio::CloudflareStream::Api::Error => e
      Rails.logger.warn("Cloudflare Stream signed playback token failed for video #{video.id}: #{e.message}")
      nil
    end

    def fetch_and_cache_signed_url_token(uid)
      token = Folio::CloudflareStream::Api.new.signed_url_token(
        uid,
        expires_at: Time.current + signed_url_token_expires_in,
      )
      Rails.cache.write(signed_url_token_cache_key(uid), token, expires_in: signed_url_token_cache_expires_in) if token.present?
      token
    end

    def signed_url_token_expires_in
      Rails.application.config.folio_cloudflare_stream_signed_url_token_expires_in
    end

    def signed_url_token_cache_expires_in
      seconds = signed_url_token_expires_in.to_i - SIGNED_URL_TOKEN_CACHE_SAFETY_MARGIN.to_i
      [seconds, 1].max.seconds
    end

    def signed_url_token_cache_key(uid)
      "folio/cloudflare_stream/signed_url_token/#{uid}/#{signed_url_token_expires_in.to_i}"
    end

    def replace_playback_identifier(url, replacement)
      uri = URI.parse(url)
      uid = data["uid"].presence
      return if uid.blank?

      segments = uri.path.split("/")
      index = segments.index(uid)
      return if index.blank?

      segments[index] = replacement
      uri.path = segments.join("/")
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end
end
