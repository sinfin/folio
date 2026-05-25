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
end
