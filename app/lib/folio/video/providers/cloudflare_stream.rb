# frozen_string_literal: true

require "uri"

class Folio::Video::Providers::CloudflareStream < Folio::Video::Providers::Base
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
    data["iframe_url"].presence || iframe_url_from_playback_host
  end

  def poster_url
    data["thumbnail"].presence
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

      { src:, type:, label: }
    end

    def status_state
      data.dig("status", "state").to_s
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
end
