# frozen_string_literal: true

require "test_helper"

class Folio::CloudflareStream::CheckProgressJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CloudflareStream::FileProcessing
  end

  test "stores ready playback metadata and marks video ready" do
    video = build_video

    api = RecordingApi.new({
      "uid" => "stream-1",
      "readyToStream" => true,
      "status" => { "state" => "ready" },
      "duration" => 12.4,
      "thumbnail" => "https://customer-code.cloudflarestream.com/stream-1/thumbnails/thumbnail.jpg",
      "playback" => {
        "hls" => "https://customer-code.cloudflarestream.com/stream-1/manifest/video.m3u8",
        "dash" => "https://customer-code.cloudflarestream.com/stream-1/manifest/video.mpd",
      },
    })

    Folio::CloudflareStream::Api.stub(:new, api) do
      assert_no_enqueued_jobs only: Folio::CloudflareStream::CheckProgressJob do
        Folio::CloudflareStream::CheckProgressJob.perform_now(video, encoding_generation: 123)
      end
    end

    assert_equal "stream-1", api.video_identifier

    video.reload
    assert_equal "ready", video.aasm_state
    assert_equal "ready", video.remote_services_data["processing_state"]
    assert_equal true, video.remote_services_data["ready_to_stream"]
    assert_equal 12.4, video.remote_services_data["duration"]
  end

  test "keeps processing videos queued for another poll" do
    video = build_video

    api = RecordingApi.new({
      "uid" => "stream-1",
      "readyToStream" => false,
      "status" => { "state" => "downloading" },
    })

    Folio::CloudflareStream::Api.stub(:new, api) do
      assert_enqueued_jobs 1, only: Folio::CloudflareStream::CheckProgressJob do
        Folio::CloudflareStream::CheckProgressJob.perform_now(video, encoding_generation: 123)
      end
    end

    assert_equal "processing", video.reload.remote_services_data["processing_state"]
  end

  test "stores last progress check time when video is still processing" do
    video = build_video
    checked_at = Time.zone.parse("2026-05-26 10:00:00")

    api = RecordingApi.new({
      "uid" => "stream-1",
      "readyToStream" => false,
      "status" => { "state" => "downloading" },
    })

    travel_to checked_at do
      Folio::CloudflareStream::Api.stub(:new, api) do
        Folio::CloudflareStream::CheckProgressJob.perform_now(video, encoding_generation: 123)
      end
    end

    assert_equal checked_at.iso8601, video.reload.remote_services_data["last_progress_check_at"]
  end

  test "marks video failed when Cloudflare reports error" do
    video = build_video

    api = RecordingApi.new({
      "uid" => "stream-1",
      "readyToStream" => false,
      "status" => {
        "state" => "error",
        "errorReasonText" => "Unsupported format",
      },
    })

    Folio::CloudflareStream::Api.stub(:new, api) do
      assert_no_enqueued_jobs only: Folio::CloudflareStream::CheckProgressJob do
        Folio::CloudflareStream::CheckProgressJob.perform_now(video, encoding_generation: 123)
      end
    end

    video.reload
    assert_equal "processing_failed", video.aasm_state
    assert_equal "failed", video.remote_services_data["processing_state"]
    assert_equal "Unsupported format", video.remote_services_data["error_message"]
  end

  test "keeps video processing on transient API error" do
    video = build_video
    api = FailingApi.new(Folio::CloudflareStream::Api::Error.new("rate limited", status_code: 429))

    Folio::CloudflareStream::Api.stub(:new, api) do
      assert_raises(Folio::CloudflareStream::Api::Error) do
        Folio::CloudflareStream::CheckProgressJob.perform_now(video, encoding_generation: 123)
      end
    end

    video.reload
    assert_equal "processing", video.aasm_state
    assert_equal "processing", video.remote_services_data["processing_state"]
    assert_equal "rate limited", video.remote_services_data["last_api_error"]
  end

  test "marks video failed when Cloudflare video is not found" do
    video = build_video
    api = FailingApi.new(Folio::CloudflareStream::Api::Error.new("not found", status_code: 404))

    Folio::CloudflareStream::Api.stub(:new, api) do
      assert_no_enqueued_jobs only: Folio::CloudflareStream::CheckProgressJob do
        Folio::CloudflareStream::CheckProgressJob.perform_now(video, encoding_generation: 123)
      end
    end

    video.reload
    assert_equal "processing_failed", video.aasm_state
    assert_equal "failed", video.remote_services_data["processing_state"]
    assert_equal "Cloudflare Stream video not found: not found", video.remote_services_data["error_message"]
  end

  private
    def build_video
      video = TestVideoFile.new(site: get_any_site)
      video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
      video.dont_run_after_save_jobs = true
      expect_method_called_on(object: video, method: :create_full_media) { video.save! }
      video.update_columns(aasm_state: "processing",
                           remote_services_data: {
                             "service" => "cloudflare_stream",
                             "uid" => "stream-1",
                             "encoding_generation" => 123,
                             "processing_state" => "processing",
                             "poll_attempts" => 0,
                           })
      video
    end

    class RecordingApi
      attr_reader :video_identifier

      def initialize(video_response)
        @video_response = video_response
      end

      def video(identifier)
        @video_identifier = identifier
        @video_response
      end
    end

    class FailingApi
      def initialize(error)
        @error = error
      end

      def video(_identifier)
        raise @error
      end
    end
end
