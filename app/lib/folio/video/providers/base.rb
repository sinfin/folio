# frozen_string_literal: true

class Folio::Video::Providers::Base
  attr_reader :video

  def initialize(video)
    @video = video
  end

  def ready?
    false
  end

  def sources
    []
  end

  def embed_url
    nil
  end

  def poster_url
    nil
  end

  def processing_state
    return "failed" if video.respond_to?(:processing_failed?) && video.processing_failed?
    return "ready" if ready?
    return "processing" if video.respond_to?(:processing?) && video.processing?

    "pending"
  end

  def error_message
    data["error_message"].presence ||
      data.dig("status", "errorReasonText").presence ||
      data.dig("status", "errorReasonCode").presence
  end

  def content_url
    nil
  end

  def seo_metadata
    {
      title: title.presence,
      description: description.presence,
      thumbnail_url: poster_url.presence,
      upload_date: video.created_at&.iso8601,
      duration: duration_iso8601,
      content_url: content_url.presence,
      embed_url: embed_url.presence,
    }.compact
  end

  private
    def data
      video.remote_services_data || {}
    end

    def title
      video.try(:headline).presence || video.try(:title).presence || video.file_name
    end

    def description
      video.try(:description)
    end

    def duration_seconds
      data["duration"].presence || video.try(:file_track_duration)
    end

    def duration_iso8601
      seconds = duration_seconds
      return if seconds.blank? || seconds.to_f <= 0

      normalized = seconds.to_f == seconds.to_i ? seconds.to_i : seconds.to_f
      ActiveSupport::Duration.build(normalized).iso8601
    end
end
