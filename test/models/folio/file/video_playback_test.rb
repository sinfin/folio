# frozen_string_literal: true

require "test_helper"

class Folio::File::VideoPlaybackTest < ActiveSupport::TestCase
  test "direct provider exposes expiring playback source but no SEO content URL" do
    video = Folio::File::Video.new(
      file_name: "clip.mp4",
      file_mime_type: "video/mp4",
      file_uid: "videos/clip.mp4",
      created_at: Time.zone.parse("2026-05-25 10:00:00"),
      file_track_duration: 123,
    )
    file = Struct.new(:captured_expires) do
      def remote_url(expires:)
        self.captured_expires = expires
        "https://s3.example.com/videos/clip.mp4?X-Amz-Expires=3600"
      end
    end.new

    video.stub(:ready?, true) do
      video.stub(:file, file) do
        assert_equal "direct_file", video.video_playback_provider_key
        assert video.video_playback_ready?
        assert_equal [
          {
            src: "https://s3.example.com/videos/clip.mp4?X-Amz-Expires=3600",
            type: "video/mp4",
            label: "Original",
          }
        ], video.video_playback_sources
      end
    end

    assert file.captured_expires.is_a?(Time)

    metadata = video.video_seo_metadata
    assert_equal "clip.mp4", metadata[:title]
    assert_equal "PT2M3S", metadata[:duration]
    assert_nil metadata[:content_url]
    assert_nil metadata[:embed_url]
  end

  test "cloudflare provider exposes stored playback outputs without original source URL" do
    video = Folio::File::Video.new(
      file_name: "cloudflare.mp4",
      headline: "Cloudflare headline",
      description: "Cloudflare description",
      file_mime_type: "video/mp4",
      file_uid: "videos/original.mp4",
      created_at: Time.zone.parse("2026-05-25 10:00:00"),
      remote_services_data: {
        "service" => "cloudflare_stream",
        "uid" => "abc123",
        "ready_to_stream" => true,
        "status" => { "state" => "ready" },
        "thumbnail" => "https://customer-code.cloudflarestream.com/abc123/thumbnails/thumbnail.jpg",
        "preview" => "https://customer-code.cloudflarestream.com/abc123/watch",
        "duration" => 45.2,
        "playback" => {
          "hls" => "https://customer-code.cloudflarestream.com/abc123/manifest/video.m3u8",
          "dash" => "https://customer-code.cloudflarestream.com/abc123/manifest/video.mpd",
        },
      },
    )

    assert_equal "cloudflare_stream", video.video_playback_provider_key
    assert video.video_playback_ready?
    assert_equal [
      {
        src: "https://customer-code.cloudflarestream.com/abc123/manifest/video.m3u8",
        type: "application/x-mpegURL",
        label: "HLS",
      },
      {
        src: "https://customer-code.cloudflarestream.com/abc123/manifest/video.mpd",
        type: "application/dash+xml",
        label: "DASH",
      },
    ], video.video_playback_sources
    assert_equal "https://customer-code.cloudflarestream.com/abc123/iframe", video.video_playback_embed_url
    assert_equal "https://customer-code.cloudflarestream.com/abc123/thumbnails/thumbnail.jpg", video.video_playback_poster_url

    metadata = video.video_seo_metadata
    assert_equal "Cloudflare headline", metadata[:title]
    assert_equal "Cloudflare description", metadata[:description]
    assert_equal "https://customer-code.cloudflarestream.com/abc123/thumbnails/thumbnail.jpg", metadata[:thumbnail_url]
    assert_equal "https://customer-code.cloudflarestream.com/abc123/iframe", metadata[:embed_url]
    assert_nil metadata[:content_url]
  end

  test "existing provider metadata keeps provider key independent of configured provider" do
    video = Folio::File::Video.new(remote_services_data: {
      "service" => "cloudflare_stream",
      "uid" => "abc123",
    })

    with_config(folio_files_video_default_processing_provider: :direct_file) do
      assert_equal "cloudflare_stream", video.video_playback_provider_key
    end
  end
end
