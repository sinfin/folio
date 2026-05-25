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
      meta: {
        name: "blank.mp4",
        folio_file_id: video.id,
      },
    }, api.copy_args)

    video.reload
    assert_equal "cloudflare_stream", video.remote_services_data["service"]
    assert_equal "stream-1", video.remote_services_data["uid"]
    assert_equal false, video.remote_services_data["ready_to_stream"]
    assert_equal "processing", video.remote_services_data["processing_state"]
    assert_equal "https://customer-code.cloudflarestream.com/stream-1/manifest/video.m3u8",
                 video.remote_services_data.dig("playback", "hls")
    assert_not_includes video.remote_services_data.to_json, "X-Amz-Expires"
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
end
