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

  test "existing provider metadata keeps provider key independent of configured provider" do
    video = Folio::File::Video.new(remote_services_data: {
      "service" => "cloudflare_stream",
      "uid" => "abc123",
    })

    with_config(folio_files_video_default_processing_provider: :direct_file) do
      assert_equal "cloudflare_stream", video.video_playback_provider_key
    end
  end

  test "unknown video provider raises clear error" do
    video = Folio::File::Video.new(remote_services_data: { "service" => "missing_provider" })

    error = assert_raises(Folio::Video::Providers::UnknownProviderError) do
      video.video_playback_ready?
    end

    assert_includes error.message, "missing_provider"
    assert_includes error.message, "folio_files_video_playback_provider_classes"
  end

  test "configured provider class must be available" do
    video = Folio::File::Video.new(remote_services_data: { "service" => "cloudflare_stream" })

    with_config(folio_files_video_playback_provider_classes: {
      "direct_file" => "Folio::Video::Providers::DirectFile",
      "cloudflare_stream" => "Folio::MissingCloudflareStreamProvider",
    }) do
      error = assert_raises(Folio::Video::Providers::UnavailableProviderError) do
        video.video_playback_ready?
      end

      assert_includes error.message, "cloudflare_stream"
      assert_includes error.message, "Folio.enabled_packs"
    end
  end
end
