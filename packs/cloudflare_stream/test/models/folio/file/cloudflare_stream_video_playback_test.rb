# frozen_string_literal: true

require "test_helper"

class Folio::File::CloudflareStreamVideoPlaybackTest < ActiveSupport::TestCase
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

  test "cloudflare provider signs playback URLs when required" do
    video = Folio::File::Video.new(
      file_name: "private.mp4",
      remote_services_data: {
        "service" => "cloudflare_stream",
        "uid" => "abc123",
        "ready_to_stream" => true,
        "require_signed_urls" => true,
        "thumbnail" => "https://customer-code.cloudflarestream.com/abc123/thumbnails/thumbnail.jpg",
        "playback" => {
          "hls" => "https://customer-code.cloudflarestream.com/abc123/manifest/video.m3u8",
          "dash" => "https://customer-code.cloudflarestream.com/abc123/manifest/video.mpd",
        },
      },
    )

    api = RecordingTokenApi.new("signed-token")

    Folio::CloudflareStream::Api.stub(:new, api) do
      assert_equal "https://customer-code.cloudflarestream.com/signed-token/iframe", video.video_playback_embed_url
      assert_equal [
        {
          src: "https://customer-code.cloudflarestream.com/signed-token/manifest/video.m3u8",
          type: "application/x-mpegURL",
          label: "HLS",
        },
        {
          src: "https://customer-code.cloudflarestream.com/signed-token/manifest/video.mpd",
          type: "application/dash+xml",
          label: "DASH",
        },
      ], video.video_playback_sources
      assert_equal "https://customer-code.cloudflarestream.com/signed-token/thumbnails/thumbnail.jpg",
                   video.video_playback_poster_url
    end

    assert_equal 1, api.calls.size
    assert_equal "abc123", api.calls.first[:identifier]
    assert api.calls.first[:expires_at].is_a?(Time)
  end

  test "cloudflare provider omits signed playback URLs from SEO metadata" do
    video = Folio::File::Video.new(
      file_name: "private.mp4",
      headline: "Private title",
      description: "Private description",
      remote_services_data: {
        "service" => "cloudflare_stream",
        "uid" => "abc123",
        "ready_to_stream" => true,
        "require_signed_urls" => true,
        "thumbnail" => "https://customer-code.cloudflarestream.com/abc123/thumbnails/thumbnail.jpg",
        "playback" => {
          "hls" => "https://customer-code.cloudflarestream.com/abc123/manifest/video.m3u8",
        },
      },
    )

    Folio::CloudflareStream::Api.stub(:new, -> { raise "token API should not be called for SEO metadata" }) do
      metadata = video.video_seo_metadata

      assert_equal "Private title", metadata[:title]
      assert_equal "Private description", metadata[:description]
      assert_nil metadata[:thumbnail_url]
      assert_nil metadata[:embed_url]
      assert_nil metadata[:content_url]
    end
  end

  class RecordingTokenApi
    attr_reader :calls

    def initialize(token)
      @token = token
      @calls = []
    end

    def signed_url_token(identifier, expires_at:)
      @calls << { identifier: identifier, expires_at: expires_at }
      @token
    end
  end
end
