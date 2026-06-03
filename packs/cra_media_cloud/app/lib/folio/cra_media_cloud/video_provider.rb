# frozen_string_literal: true

class Folio::CraMediaCloud::VideoProvider < Folio::Video::Providers::Base
  def ready?
    video.ready? && sources.any?
  end

  def sources
    [
      hls_source,
      dash_source,
      mp4_source,
    ].compact
  end

  def poster_url
    video.remote_cover_url if video.respond_to?(:remote_cover_url)
  end

  def content_url
    video.remote_content_mp4_url_for(:hd2) if video.respond_to?(:remote_content_mp4_url_for)
  end

  private
    def hls_source
      return unless video.respond_to?(:remote_manifest_hls_url)
      return if video.remote_manifest_hls_url.blank?

      {
        src: video.remote_manifest_hls_url,
        type: "application/x-mpegURL",
        label: "HLS",
      }
    end

    def dash_source
      return unless video.respond_to?(:remote_manifest_dash_url)
      return if video.remote_manifest_dash_url.blank?

      {
        src: video.remote_manifest_dash_url,
        type: "application/dash+xml",
        label: "DASH",
      }
    end

    def mp4_source
      return unless video.respond_to?(:remote_content_mp4_url_for)

      src = video.remote_content_mp4_url_for(:hd2).presence ||
            video.remote_content_mp4_url_for(:hd).presence ||
            video.remote_content_mp4_url_for(:sd).presence
      return if src.blank?

      {
        src: src,
        type: "video/mp4",
        label: "MP4",
      }
    end
end
