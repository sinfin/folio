# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::CheckProgressJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CraMediaCloud::FileProcessing
  end

  # --- Encoding generation tests ---

  test "skips processing when encoding_generation doesn't match (stale job)" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => 12345,
      "reference_id" => "REF123"
    ))

    # Job with old generation should be skipped - no new CheckProgressJob enqueued
    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video, encoding_generation: 11111)
    end

    # Video state should be unchanged
    video.reload
    assert_equal "full_media_processing", video.remote_services_data["processing_state"]
  end

  test "processes normally when encoding_generation matches" do
    video = create_test_video_in_processing_state
    current_generation = 12345
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => current_generation,
      "reference_id" => "REF123"
    ))

    api_response = { "id" => "JOB123", "status" => "PROCESSING", "progress" => 0.5,
                     "lastModified" => Time.current.iso8601 }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    # Job with matching generation should process and reschedule
    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video, encoding_generation: current_generation)
      end
    end

    api_mock.verify
  end

  test "processes normally when encoding_generation is nil (backwards compatibility)" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "reference_id" => "REF123"
    ))

    api_response = { "id" => "JOB123", "status" => "PROCESSING", "progress" => 0.5,
                     "lastModified" => Time.current.iso8601 }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    # Job without generation (old jobs) should still process
    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    api_mock.verify
  end

  test "skips already ready video regardless of encoding_generation" do
    video = create_test_video_in_processing_state
    video.update_column(:aasm_state, "ready")
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => 12345,
      "reference_id" => "REF123"
    ))

    # Should skip because video is already ready
    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video, encoding_generation: 12345)
    end
  end

  private
    def create_test_video_in_processing_state
      video = TestVideoFile.new(site: get_any_site)
      video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
      video.dont_run_after_save_jobs = true

      # Stub create_full_media to prevent the full processing chain during save
      expect_method_called_on(object: video, method: :create_full_media) do
        video.save!
      end

      # Set desired initial state (merge to preserve encoding_generation from process_attached_file)
      video.update!(remote_services_data: video.remote_services_data.merge(
        "service" => "cra_media_cloud",
        "processing_state" => "full_media_processing"
      ))
      video
    end
end
