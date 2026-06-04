# frozen_string_literal: true

require "test_helper"

class Folio::CloudflareStream::CreateMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CloudflareStream::FileProcessing
  end

  test "copies source URL and stores playback metadata without persisting ingest URL" do
    video = build_video
    api = RecordingApi.new({
      "uid" => "stream-1",
      "readyToStream" => false,
      "status" => { "state" => "downloading" },
      "thumbnail" => "https://customer-code.cloudflarestream.com/stream-1/thumbnails/thumbnail.jpg",
      "preview" => "https://customer-code.cloudflarestream.com/stream-1/watch",
      "playback" => {
        "hls" => "https://customer-code.cloudflarestream.com/stream-1/manifest/video.m3u8",
        "dash" => "https://customer-code.cloudflarestream.com/stream-1/manifest/video.mpd",
      },
    })

    video.stub(:cloudflare_stream_source_url, "https://s3.example.com/source.mp4?X-Amz-Expires=3600") do
      Folio::CloudflareStream::Api.stub(:new, api) do
        assert_enqueued_jobs 1, only: Folio::CloudflareStream::CheckProgressJob do
          Folio::CloudflareStream::CreateMediaJob.perform_now(video)
        end
      end
    end

    assert_equal({
      url: "https://s3.example.com/source.mp4?X-Amz-Expires=3600",
      allowed_origins: [],
      meta: {
        name: "blank.mp4",
        folio_file_id: video.id.to_s,
      },
      require_signed_urls: false,
    }, api.copy_args)

    video.reload
    assert_equal "cloudflare_stream", video.remote_services_data["service"]
    assert_equal false, video.remote_services_data["require_signed_urls"]
    assert_equal "stream-1", video.remote_services_data["uid"]
    assert_equal false, video.remote_services_data["ready_to_stream"]
    assert_equal "processing", video.remote_services_data["processing_state"]
    assert_equal "https://customer-code.cloudflarestream.com/stream-1/manifest/video.m3u8",
                 video.remote_services_data.dig("playback", "hls")
    assert_not_includes video.remote_services_data.to_json, "X-Amz-Expires"
  end

  test "copies source URL with configured playback restrictions" do
    video = build_video
    api = RecordingApi.new({
      "uid" => "stream-1",
      "readyToStream" => false,
      "status" => { "state" => "downloading" },
    })

    original_allowed_origins = Rails.application.config.folio_cloudflare_stream_allowed_origins
    original_require_signed_urls = Rails.application.config.folio_cloudflare_stream_require_signed_urls
    Rails.application.config.folio_cloudflare_stream_allowed_origins = ["fullmoonzine.cz", "www.fullmoonzine.cz"]
    Rails.application.config.folio_cloudflare_stream_require_signed_urls = true

    video.stub(:cloudflare_stream_source_url, "https://s3.example.com/source.mp4?X-Amz-Expires=3600") do
      Folio::CloudflareStream::Api.stub(:new, api) do
        assert_enqueued_jobs 1, only: Folio::CloudflareStream::CheckProgressJob do
          Folio::CloudflareStream::CreateMediaJob.perform_now(video)
        end
      end
    end

    assert_equal ["fullmoonzine.cz", "www.fullmoonzine.cz"], api.copy_args[:allowed_origins]
    assert_equal true, api.copy_args[:require_signed_urls]
    assert_equal true, video.reload.remote_services_data["require_signed_urls"]
  ensure
    Rails.application.config.folio_cloudflare_stream_allowed_origins = original_allowed_origins
    Rails.application.config.folio_cloudflare_stream_require_signed_urls = original_require_signed_urls
  end

  test "marks ready immediately when Cloudflare already reports readyToStream" do
    video = build_video
    video.update_column(:aasm_state, "processing")

    api = RecordingApi.new({
      "uid" => "stream-1",
      "readyToStream" => true,
      "status" => { "state" => "ready" },
      "playback" => {
        "hls" => "https://customer-code.cloudflarestream.com/stream-1/manifest/video.m3u8",
      },
    })

    video.stub(:cloudflare_stream_source_url, "https://s3.example.com/source.mp4?X-Amz-Expires=3600") do
      Folio::CloudflareStream::Api.stub(:new, api) do
        assert_no_enqueued_jobs only: Folio::CloudflareStream::CheckProgressJob do
          Folio::CloudflareStream::CreateMediaJob.perform_now(video)
        end
      end
    end

    assert_equal "ready", video.reload.aasm_state
    assert_equal "ready", video.remote_services_data["processing_state"]
  end

  test "keeps video processing on transient API error" do
    video = build_video
    api = FailingApi.new

    video.stub(:cloudflare_stream_source_url, "https://s3.example.com/source.mp4?X-Amz-Expires=3600") do
      Folio::CloudflareStream::Api.stub(:new, api) do
        assert_raises(Folio::CloudflareStream::Api::Error) do
          Folio::CloudflareStream::CreateMediaJob.perform_now(video)
        end
      end
    end

    video.reload
    assert_equal "processing", video.aasm_state
    assert_equal "processing", video.remote_services_data["processing_state"]
    assert_equal "rate limited", video.remote_services_data["last_api_error"]
  end

  private
    def build_video
      video = TestVideoFile.new(site: get_any_site)
      video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
      video.dont_run_after_save_jobs = true
      expect_method_called_on(object: video, method: :create_full_media) { video.save! }
      video.update_columns(aasm_state: "processing",
                           remote_services_data: {
                             "encoding_generation" => 123,
                             "processing_state" => "enqueued",
                             "service" => "cloudflare_stream",
                           })
      video
    end

    class RecordingApi
      attr_reader :copy_args

      def initialize(copy_response)
        @copy_response = copy_response
      end

      def copy(**args)
        @copy_args = args
        @copy_response
      end
    end

    class FailingApi
      def copy(**)
        raise Folio::CloudflareStream::Api::Error, "rate limited"
      end
    end
end
